create table if not exists public.cart_runtime_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now(),
  updated_by text,
  constraint cart_runtime_config_key_check check (
    key in ('pending_order_ttl_minutes')
  ),
  constraint cart_runtime_config_value_not_blank check (btrim(value) <> ''),
  constraint cart_runtime_config_ttl_minutes_range check (
    key <> 'pending_order_ttl_minutes'
    or case
      when value ~ '^\d+$' then value::integer between 1 and 43200
      else false
    end
  )
);

alter table public.cart_runtime_config enable row level security;

revoke all on public.cart_runtime_config from public, anon, authenticated;
grant select, insert, update on public.cart_runtime_config to service_role;

insert into public.cart_runtime_config (key, value)
values ('pending_order_ttl_minutes', '1440')
on conflict (key) do nothing;

comment on table public.cart_runtime_config is
  'Runtime configuration for cart checkout behavior. Values are backend-only.';

comment on column public.cart_runtime_config.value is
  'pending_order_ttl_minutes defaults to 1440 minutes (1 day).';

create or replace function public.cart_pending_order_ttl()
returns interval
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_raw_value text;
  v_minutes integer := 1440;
begin
  select crc.value
  into v_raw_value
  from public.cart_runtime_config crc
  where crc.key = 'pending_order_ttl_minutes';

  if v_raw_value ~ '^\d+$' then
    v_minutes := v_raw_value::integer;
  end if;

  if v_minutes < 1 then
    v_minutes := 1440;
  elsif v_minutes > 43200 then
    v_minutes := 43200;
  end if;

  return make_interval(mins => v_minutes);
end;
$function$;

revoke all on function public.cart_pending_order_ttl()
from public, anon, authenticated;

grant execute on function public.cart_pending_order_ttl()
to service_role;

create or replace function public.set_cart_order_payment_expiration()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.order_number like 'CART-%'
    and new.order_status::text = 'pending'
    and new.payment_status::text = 'unpaid'
    and new.payment_expires_at is null
  then
    new.payment_expires_at := now() + public.cart_pending_order_ttl();
  end if;

  return new;
end;
$function$;

drop trigger if exists set_cart_order_payment_expiration
on public.orders;

create trigger set_cart_order_payment_expiration
before insert on public.orders
for each row
execute function public.set_cart_order_payment_expiration();

create index if not exists orders_cart_pending_expiration_idx
on public.orders(payment_expires_at)
where payment_expires_at is not null;

update public.orders o
set
  payment_expires_at = o.created_at + public.cart_pending_order_ttl(),
  updated_at = now()
where o.order_number like 'CART-%'
  and o.order_status::text = 'pending'
  and o.payment_status::text = 'unpaid'
  and coalesce(o.paid_amount, 0) = 0
  and o.payment_expires_at is null
  and not exists (
    select 1
    from public.payments p
    where p.order_id = o.id
  );

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

notify pgrst, 'reload schema';
