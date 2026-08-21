-- MIT-143: when a customer explicitly cancels payment on the Laropay gateway,
-- or an order is swept by TTL for payment abandonment, the related order must
-- be cancelled and its reserved resources released: product stock restored,
-- the associated appointment slot freed, and the Laropay link marked
-- cancelled. Traceability is kept on public.orders.

alter table public.orders
  add column if not exists cancellation_reason text,
  add column if not exists cancelled_at timestamptz;

-- Shared core used both by explicit-cancellation handling
-- (persist_laropay_status_check) and by the abandoned-order sweeps
-- (expire_abandoned_cart_orders / expire_abandoned_appointment_orders).
-- Mirrors the stock-restore pattern already used by
-- expire_abandoned_cart_orders (202608130001) and dynamically resolves enum
-- labels since the underlying CREATE TYPE statements predate this repo's
-- tracked migrations.
create or replace function public.cancel_order_and_release_resources(
  p_order_id uuid,
  p_cancellation_reason text,
  p_cancelled_by text default 'system'
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

  -- Safety guard: only cancel orders that are still genuinely pending and
  -- unpaid. This protects against a race where the order was already paid
  -- through another channel (e.g. cash at the workshop) between the
  -- customer opening the Laropay link and cancelling it -- callers such as
  -- persist_laropay_status_check invoke this without pre-filtering by
  -- order_status themselves.
  if v_order.order_status::text <> 'pending'
    or v_order.payment_status::text <> 'unpaid'
    or coalesce(v_order.paid_amount, 0) <> 0
    or exists (
      select 1
      from public.payments p
      where p.order_id = p_order_id
    )
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
  -- appointment_status already uses 'cancelled' consistently elsewhere
  -- (see the availability filters in 202606260001/202607210001/202607270001),
  -- unlike order_status/product_status which need dynamic resolution above.
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

revoke all on function public.cancel_order_and_release_resources(uuid, text, text)
from public, anon, authenticated;

grant execute on function public.cancel_order_and_release_resources(uuid, text, text)
to service_role;

-- Extend persist_laropay_status_check (202607270002) to recognize an
-- explicit-cancellation status and release resources atomically with the
-- status persistence. All existing 'paid' branch logic is unchanged.
create or replace function public.persist_laropay_status_check(
  p_payment_link_id uuid,
  p_status text,
  p_response_code text,
  p_response_description text,
  p_reject_reason text,
  p_auth_response_code text,
  p_verify_payload jsonb,
  p_certifier_payload jsonb,
  p_status_checked_at timestamptz,
  p_status_check_error text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment_link public.laropay_payment_links%rowtype;
  v_effective_status text;
  v_order_id uuid;
  v_order_workshop_id uuid;
  v_updated_order_count integer;
  v_card_payment_method_id integer;
  v_payment_reference text;
  v_total_paid numeric;
begin
  if p_status not in ('paid', 'pending', 'rejected', 'expired', 'failed', 'cancelled') then
    raise exception 'invalid_laropay_status';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_payment_link_id::text, 0));

  select *
  into v_payment_link
  from public.laropay_payment_links
  where id = p_payment_link_id
  for update;

  if not found then
    raise exception 'payment_link_not_found';
  end if;

  v_effective_status := lower(coalesce(v_payment_link.status, ''));

  if v_effective_status <> 'paid' then
    if p_status <> 'paid' and v_effective_status in ('rejected', 'expired', 'cancelled') then
      return to_jsonb(v_payment_link);
    end if;

    v_effective_status := p_status;

    update public.laropay_payment_links
    set
      status = v_effective_status,
      response_code = p_response_code,
      response_description = p_response_description,
      reject_reason = p_reject_reason,
      auth_response_code = p_auth_response_code,
      response_payload = coalesce(p_verify_payload, '{}'::jsonb),
      verify_payload = coalesce(p_verify_payload, '{}'::jsonb),
      certifier_payload = coalesce(p_certifier_payload, '{}'::jsonb),
      status_checked_at = p_status_checked_at,
      status_check_error = p_status_check_error
    where id = p_payment_link_id
    returning * into v_payment_link;
  end if;

  if v_effective_status = 'cancelled' then
    begin
      perform public.cancel_order_and_release_resources(
        v_payment_link.internal_transaction_id::uuid,
        'laropay_customer_cancelled',
        'laropay'
      );
    exception
      when invalid_text_representation then
        raise exception 'invalid_internal_transaction_id';
    end;
  end if;

  if v_effective_status = 'paid' then
    begin
      v_order_id := v_payment_link.internal_transaction_id::uuid;
    exception
      when invalid_text_representation then
        raise exception 'invalid_internal_transaction_id';
    end;

    if v_payment_link.amount <= 0 then
      raise exception 'invalid_laropay_payment_amount';
    end if;

    v_payment_reference := 'LAROPAY:' || v_payment_link.id::text;

    select o.workshop_id
    into v_order_workshop_id
    from public.orders o
    where o.id = v_order_id
    for update;

    if not found then
      raise exception 'payment_order_not_found';
    end if;

    select pm.id
    into v_card_payment_method_id
    from public.workshop_payment_methods wpm
    join public.payment_methods pm on pm.id = wpm.payment_method_id
    where wpm.workshop_id = v_order_workshop_id
      and translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
        'tarjeta',
        'tarjeta credito',
        'tarjeta de credito',
        'tarjeta debito',
        'tarjeta de debito'
      )
    order by
      case
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') = 'tarjeta' then 0
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
          'tarjeta credito',
          'tarjeta de credito'
        ) then 1
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
          'tarjeta debito',
          'tarjeta de debito'
        ) then 2
        else 4
      end,
      pm.id
    limit 1;

    if v_card_payment_method_id is null then
      raise exception 'laropay_card_payment_method_not_found';
    end if;

    insert into public.payments (
      id,
      order_id,
      amount,
      payment_method_id,
      payment_date,
      reference_number,
      notes,
      updated_at
    )
    select
      gen_random_uuid(),
      v_order_id,
      v_payment_link.amount,
      v_card_payment_method_id,
      coalesce(p_status_checked_at, v_payment_link.status_checked_at, now()),
      v_payment_reference,
      'Pago Laropay confirmado. link_id=' || coalesce(v_payment_link.link_id, ''),
      now()
    where not exists (
      select 1
      from public.payments p
      where p.order_id = v_order_id
        and p.reference_number = v_payment_reference
    )
    on conflict (order_id, reference_number)
      where reference_number is not null
      do nothing;

    select coalesce(sum(p.amount), 0)
    into v_total_paid
    from public.payments p
    where p.order_id = v_order_id;

    -- Customer-created orders can include service balances paid at the workshop.
    -- Laropay settles only product payments, so remaining service balance is partial.
    update public.orders o
    set
      payment_status = case
        when v_total_paid <= 0 then 'unpaid'
        when o.total_amount is null then 'partial'
        when v_total_paid >= o.total_amount then 'paid'
        else 'partial'
      end::public.payment_status,
      paid_amount = v_total_paid,
      remaining_amount = case
        when o.total_amount is null then null
        else greatest(o.total_amount - v_total_paid, 0)
      end,
      updated_at = now()
    where o.id = v_order_id;

    get diagnostics v_updated_order_count = row_count;
    if v_updated_order_count <> 1 then
      raise exception 'payment_order_not_found';
    end if;
  end if;

  return to_jsonb(v_payment_link);
end;
$$;

revoke all on function public.persist_laropay_status_check(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  timestamptz,
  text
) from public, anon, authenticated;

grant execute on function public.persist_laropay_status_check(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  timestamptz,
  text
) to service_role;

-- Twin of expire_abandoned_cart_orders (202608130001) for appointment
-- orders. Unlike cart orders, appointment orders never get a TTL just from
-- being booked (see 202606240001 keep_appointment_order_active) -- they
-- only receive payment_expires_at when a Laropay link is actually generated
-- for them (see laropay-generate-link), bounded by the appointment's own
-- scheduled_datetime so a future appointment is never expired early.
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
      and o.order_status::text = 'pending'
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
      'payment_ttl_expired',
      'system'
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

-- Actually schedule both sweeps -- expire_abandoned_cart_orders has existed
-- since 202608130001 but nothing has ever invoked it.
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'expire-abandoned-cart-orders',
  '*/15 * * * *',
  $$select public.expire_abandoned_cart_orders(200)$$
);

select cron.schedule(
  'expire-abandoned-appointment-orders',
  '*/15 * * * *',
  $$select public.expire_abandoned_appointment_orders(200)$$
);

notify pgrst, 'reload schema';
