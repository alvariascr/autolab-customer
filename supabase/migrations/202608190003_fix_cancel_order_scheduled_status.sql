-- Fix: order_status for a freshly booked appointment order is 'scheduled',
-- not 'pending' (confirmed against the live enum: draft, pending,
-- scheduled, in_progress, awaiting_parts, ready_for_pickup,
-- partially_delivered, completed, cancelled -- a workshop repair-order
-- lifecycle, not tracked in this repo's migrations). The eligibility guard
-- in cancel_order_and_release_resources and the candidate filter in
-- expire_abandoned_appointment_orders only matched 'pending', so real
-- appointment orders (order_status = 'scheduled') were silently skipped:
-- the Laropay link still got marked cancelled (persisted before this
-- function runs), but stock/appointment/order_status were never touched.
--
-- Fix: only block cancellation once the workshop has actually started
-- working the order (in_progress and later) -- draft/pending/scheduled are
-- all "nothing has happened yet" states where cancelling is safe.

create or replace function public.cancel_order_and_release_resources(
  p_order_id uuid,
  p_cancellation_reason text,
  p_cancelled_by uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_order public.orders%rowtype;
  v_cancelled_order_status text;
  v_cancelled_product_status text;
  v_restored_units integer := 0;
  v_released_appointments integer := 0;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_order_id::text, 0));

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'order_not_found';
  end if;

  select e.enumlabel
  into v_cancelled_order_status
  from pg_enum e
  join pg_type t on t.oid = e.enumtypid
  join pg_namespace n on n.oid = t.typnamespace
  where n.nspname = 'public'
    and t.typname = 'order_status'
    and e.enumlabel in ('cancelled', 'canceled')
  order by case e.enumlabel
    when 'cancelled' then 0
    else 1
  end
  limit 1;

  if v_cancelled_order_status is null then
    raise exception 'order_cancellation_status_not_supported';
  end if;

  if v_order.order_status::text = v_cancelled_order_status
    or v_order.order_status::text = 'expired'
  then
    return jsonb_build_object(
      'orderId', p_order_id,
      'alreadyCancelled', true,
      'restoredUnits', 0,
      'releasedAppointments', 0
    );
  end if;

  -- Safety guard: only cancel orders the workshop hasn't started working on
  -- yet, and that are still genuinely unpaid. This protects against a race
  -- where the order was already paid through another channel (e.g. cash at
  -- the workshop) or already progressed past booking between the customer
  -- opening the Laropay link and cancelling it -- callers such as
  -- persist_laropay_status_check invoke this without pre-filtering
  -- themselves.
  if v_order.order_status::text not in ('draft', 'pending', 'scheduled')
    or v_order.payment_status::text <> 'unpaid'
    or coalesce(v_order.paid_amount, 0) <> 0
  then
    return jsonb_build_object(
      'orderId', p_order_id,
      'alreadyCancelled', false,
      'skipped', true,
      'skipReason', 'order_not_eligible_for_cancellation',
      'restoredUnits', 0,
      'releasedAppointments', 0
    );
  end if;

  select e.enumlabel
  into v_cancelled_product_status
  from pg_enum e
  join pg_type t on t.oid = e.enumtypid
  join pg_namespace n on n.oid = t.typnamespace
  where n.nspname = 'public'
    and t.typname = 'product_status'
    and e.enumlabel in ('cancelled', 'canceled')
  order by case e.enumlabel
    when 'cancelled' then 0
    else 1
  end
  limit 1;

  select coalesce(sum(op.quantity), 0)::integer
  into v_restored_units
  from public.order_products op
  where op.order_id = p_order_id
    and op.product_status::text = 'pending';

  update public.inventory_items ii
  set current_stock = coalesce(ii.current_stock, 0) + restored.quantity
  from (
    select op.inventory_item_id, sum(op.quantity)::integer as quantity
    from public.order_products op
    where op.order_id = p_order_id
      and op.product_status::text = 'pending'
    group by op.inventory_item_id
  ) restored
  where ii.id = restored.inventory_item_id;

  if v_cancelled_product_status is not null then
    update public.order_products op
    set product_status = v_cancelled_product_status::public.product_status
    where op.order_id = p_order_id
      and op.product_status::text = 'pending';
  end if;

  -- Release any reserved appointment slot tied to this order's services.
  update public.appointments a
  set
    appointment_status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = p_cancelled_by,
    cancellation_reason = p_cancellation_reason
  from public.order_services os
  where os.order_id = p_order_id
    and a.order_service_id = os.id
    and a.appointment_status not in ('cancelled', 'no_show');

  get diagnostics v_released_appointments = row_count;

  update public.laropay_payment_links lpl
  set
    status = 'cancelled',
    updated_at = now()
  where lpl.internal_transaction_id = p_order_id::text
    and lpl.status in ('created', 'pending');

  update public.orders o
  set
    order_status = v_cancelled_order_status::public.order_status,
    payment_expires_at = null,
    remaining_amount = 0,
    cancellation_reason = p_cancellation_reason,
    cancelled_at = now(),
    updated_at = now()
  where o.id = p_order_id;

  return jsonb_build_object(
    'orderId', p_order_id,
    'alreadyCancelled', false,
    'restoredUnits', v_restored_units,
    'releasedAppointments', v_released_appointments
  );
end;
$function$;

revoke all on function public.cancel_order_and_release_resources(uuid, text, uuid)
from public, anon, authenticated;

grant execute on function public.cancel_order_and_release_resources(uuid, text, uuid)
to service_role;

create or replace function public.expire_abandoned_appointment_orders(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 1000));
  v_order record;
  v_result jsonb;
  v_expired_count integer := 0;
  v_restored_units integer := 0;
  v_released_appointments integer := 0;
begin
  perform pg_advisory_xact_lock(hashtextextended('appointment_order_expiration', 0));

  for v_order in
    select o.id
    from public.orders o
    where o.order_number like 'APP-%'
      and o.order_status::text in ('draft', 'pending', 'scheduled')
      and o.payment_status::text = 'unpaid'
      and coalesce(o.paid_amount, 0) = 0
      and o.payment_expires_at is not null
      and o.payment_expires_at <= now()
      and not exists (
        select 1
        from public.payments p
        where p.order_id = o.id
      )
    order by o.payment_expires_at asc
    limit v_limit
    for update skip locked
  loop
    v_result := public.cancel_order_and_release_resources(
      v_order.id,
      'payment_ttl_expired'
    );

    if not coalesce((v_result ->> 'alreadyCancelled')::boolean, false)
      and not coalesce((v_result ->> 'skipped')::boolean, false)
    then
      v_expired_count := v_expired_count + 1;
      v_restored_units := v_restored_units
        + coalesce((v_result ->> 'restoredUnits')::integer, 0);
      v_released_appointments := v_released_appointments
        + coalesce((v_result ->> 'releasedAppointments')::integer, 0);
    end if;
  end loop;

  return jsonb_build_object(
    'expiredOrders', v_expired_count,
    'restoredUnits', v_restored_units,
    'releasedAppointments', v_released_appointments
  );
end;
$function$;

revoke all on function public.expire_abandoned_appointment_orders(integer)
from public, anon, authenticated;

grant execute on function public.expire_abandoned_appointment_orders(integer)
to service_role;

notify pgrst, 'reload schema';
