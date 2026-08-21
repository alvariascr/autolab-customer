-- expire_abandoned_cart_orders (202608130001) predates orders.cancellation_reason
-- / cancelled_at (added in 202608190001), so it never populated them --
-- confirmed live: a pg_cron-swept cart order showed order_status='cancelled'
-- but cancellation_reason/cancelled_at null. Only the final UPDATE changes;
-- everything else in this function is unchanged and already verified.

create or replace function public.expire_abandoned_cart_orders(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 1000));
  v_order_ids uuid[];
  v_expired_order_status text;
  v_cancelled_product_status text;
  v_expired_count integer := 0;
  v_restored_units integer := 0;
begin
  perform pg_advisory_xact_lock(hashtextextended('cart_order_expiration', 0));

  select e.enumlabel
  into v_expired_order_status
  from pg_enum e
  join pg_type t on t.oid = e.enumtypid
  join pg_namespace n on n.oid = t.typnamespace
  where n.nspname = 'public'
    and t.typname = 'order_status'
    and e.enumlabel in ('expired', 'cancelled', 'canceled')
  order by case e.enumlabel
    when 'expired' then 0
    when 'cancelled' then 1
    else 2
  end
  limit 1;

  if v_expired_order_status is null then
    raise exception 'cart_order_expiration_status_not_supported';
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

  select coalesce(array_agg(candidate.id), array[]::uuid[])
  into v_order_ids
  from (
    select o.id
    from public.orders o
    where o.order_number like 'CART-%'
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
  ) candidate;

  if coalesce(array_length(v_order_ids, 1), 0) = 0 then
    return jsonb_build_object(
      'expiredOrders', 0,
      'restoredUnits', 0
    );
  end if;

  select coalesce(sum(op.quantity), 0)::integer
  into v_restored_units
  from public.order_products op
  where op.order_id = any(v_order_ids);

  update public.inventory_items ii
  set current_stock = coalesce(ii.current_stock, 0) + restored.quantity
  from (
    select op.inventory_item_id, sum(op.quantity)::integer as quantity
    from public.order_products op
    where op.order_id = any(v_order_ids)
    group by op.inventory_item_id
  ) restored
  where ii.id = restored.inventory_item_id;

  if v_cancelled_product_status is not null then
    update public.order_products op
    set product_status = v_cancelled_product_status::public.product_status
    where op.order_id = any(v_order_ids)
      and op.product_status::text = 'pending';
  end if;

  update public.laropay_payment_links lpl
  set
    status = 'expired',
    updated_at = now()
  where lpl.internal_transaction_id in (
      select expired_order_id.id::text
      from unnest(v_order_ids) as expired_order_id(id)
    )
    and lpl.status in ('created', 'pending');

  update public.orders o
  set
    order_status = v_expired_order_status::public.order_status,
    remaining_amount = 0,
    cancellation_reason = 'payment_ttl_expired',
    cancelled_at = now(),
    updated_at = now()
  where o.id = any(v_order_ids)
    and o.order_status::text = 'pending';

  get diagnostics v_expired_count = row_count;

  return jsonb_build_object(
    'expiredOrders', v_expired_count,
    'restoredUnits', v_restored_units
  );
end;
$function$;

revoke all on function public.expire_abandoned_cart_orders(integer)
from public, anon, authenticated;

grant execute on function public.expire_abandoned_cart_orders(integer)
to service_role;

-- Backfill CART orders that were swept before cancellation_reason/cancelled_at
-- were populated by expire_abandoned_cart_orders.
update public.orders o
set
  cancellation_reason = 'payment_ttl_expired',
  cancelled_at = coalesce(o.cancelled_at, o.updated_at),
  updated_at = now()
where o.order_number like 'CART-%'
  and o.order_status::text in ('expired', 'cancelled', 'canceled')
  and o.cancellation_reason is null
  and coalesce(o.paid_amount, 0) = 0;

notify pgrst, 'reload schema';
