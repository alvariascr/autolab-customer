create table if not exists public.order_delivery_details (
  id uuid not null default gen_random_uuid(),
  order_id uuid not null unique,
  province text not null,
  canton text not null,
  district text not null,
  exact_address text not null,
  phone text not null,
  delivery_fee numeric not null default 0,
  is_home_delivery boolean not null default true,
  is_received boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  updated_by text,
  constraint order_delivery_details_pkey primary key (id),
  constraint order_delivery_details_order_id_fkey
    foreign key (order_id) references public.orders(id)
    on delete cascade
);

alter table public.order_delivery_details
add column if not exists is_received boolean not null default false;

alter table public.order_delivery_details enable row level security;

create or replace function public.set_order_delivery_details_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

drop trigger if exists set_order_delivery_details_updated_at
  on public.order_delivery_details;

create trigger set_order_delivery_details_updated_at
before update on public.order_delivery_details
for each row
execute function public.set_order_delivery_details_updated_at();

create or replace function public.cart_tax_rate()
returns numeric
language sql
stable
set search_path to 'public'
as $function$
  select 0.13::numeric;
$function$;

drop policy if exists "customers can read own order delivery details"
  on public.order_delivery_details;

create policy "customers can read own order delivery details"
  on public.order_delivery_details
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      join public.customers c on c.id = o.customer_id
      where o.id = order_delivery_details.order_id
        and c.user_id = auth.uid()
    )
  );

revoke all on public.order_delivery_details from public;
grant select on public.order_delivery_details to authenticated;
grant all on public.order_delivery_details to service_role;

create or replace function public.create_cart_order(
  p_products jsonb,
  p_home_delivery boolean default false,
  p_delivery_details jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid;
  v_profile_name text;
  v_profile_phone text;
  v_profile_email text;
  v_customer_id uuid;
  v_order_id uuid;
  v_order_number text;
  v_workshop_id uuid;
  v_product record;
  v_validated_products jsonb := '[]'::jsonb;
  v_valid_product_count integer := 0;
  v_products_total numeric := 0;
  v_tax_total numeric := 0;
  v_delivery_fee numeric := 0;
  v_total_amount numeric := 0;
  v_delivery_province text;
  v_delivery_canton text;
  v_delivery_district text;
  v_delivery_exact_address text;
  v_delivery_phone text;
  v_workshop_address text;
  v_workshop_phone text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using message = 'cart_auth_required';
  end if;

  if p_products is null or jsonb_typeof(p_products) <> 'array' then
    raise exception using message = 'cart_products_invalid';
  end if;

  if jsonb_array_length(p_products) = 0 then
    raise exception using message = 'cart_products_required';
  end if;

  if (
    select count(distinct input.inventory_item_id)
    from jsonb_to_recordset(p_products)
      as input(inventory_item_id uuid, quantity integer)
  ) <> jsonb_array_length(p_products) then
    raise exception using message = 'cart_products_invalid';
  end if;

  select up.name, up.phone, up.email
  into v_profile_name, v_profile_phone, v_profile_email
  from public.user_profiles up
  where up.user_id = v_user_id
  limit 1;

  if coalesce(trim(v_profile_name), '') = '' then
    raise exception using message = 'cart_customer_name_required';
  end if;

  if coalesce(trim(v_profile_email), '') = '' then
    raise exception using message = 'cart_customer_email_required';
  end if;

  for v_product in
    select
      ii.id,
      ii.workshop_id,
      ii.selling_price,
      coalesce(ii.current_stock, 0) as current_stock,
      input.quantity,
      input.input_rows,
      input.invalid_quantity_count
    from (
      select
        inventory_item_id,
        sum(quantity)::integer as quantity,
        count(*)::integer as input_rows,
        count(*) filter (where quantity is null or quantity <= 0)::integer
          as invalid_quantity_count
      from jsonb_to_recordset(p_products)
        as input(inventory_item_id uuid, quantity integer)
      group by inventory_item_id
    ) input
    join public.inventory_items ii on ii.id = input.inventory_item_id
    where ii.status = 'active'
      and ii.item_type <> 'service'
    order by ii.id
    for no key update of ii
  loop
    if v_product.invalid_quantity_count > 0 or v_product.quantity <= 0 then
      raise exception using message = 'cart_products_invalid';
    end if;

    if v_product.selling_price is null or v_product.selling_price <= 0 then
      raise exception using message = 'cart_product_price_required';
    end if;

    if v_product.current_stock < v_product.quantity then
      raise exception using message = 'cart_product_stock_unavailable';
    end if;

    if v_workshop_id is null then
      v_workshop_id := v_product.workshop_id;
    elsif v_workshop_id <> v_product.workshop_id then
      raise exception using message = 'cart_products_multiple_workshops';
    end if;

    v_valid_product_count := v_valid_product_count + v_product.input_rows;
    v_validated_products :=
      v_validated_products ||
      jsonb_build_object(
        'id', v_product.id,
        'selling_price', v_product.selling_price,
        'quantity', v_product.quantity
      );

    v_products_total :=
      v_products_total + (v_product.selling_price * v_product.quantity);
  end loop;

  if v_valid_product_count <> jsonb_array_length(p_products) then
    raise exception using message = 'cart_products_invalid';
  end if;

  v_delivery_phone := coalesce(trim(p_delivery_details->>'phone'), '');

  if coalesce(trim(v_profile_phone), '') = '' and v_delivery_phone = '' then
    raise exception using message = 'cart_customer_phone_required';
  end if;

  v_customer_id := public.get_or_create_customer_for_workshop(
    p_workshop_id := v_workshop_id,
    p_name := v_profile_name,
    p_phone := coalesce(nullif(trim(v_profile_phone), ''), v_delivery_phone),
    p_email := v_profile_email,
    p_identification := null
  );

  if p_home_delivery then
    v_delivery_province := coalesce(trim(p_delivery_details->>'province'), '');
    v_delivery_canton := coalesce(trim(p_delivery_details->>'canton'), '');
    v_delivery_district := coalesce(trim(p_delivery_details->>'district'), '');
    v_delivery_exact_address :=
      coalesce(trim(p_delivery_details->>'exact_address'), '');

    if v_delivery_province = ''
      or v_delivery_canton = ''
      or v_delivery_district = ''
      or v_delivery_exact_address = ''
      or v_delivery_phone = ''
    then
      raise exception using message = 'cart_delivery_details_required';
    end if;

    select coalesce(w.delivery_fee, 0)
    into v_delivery_fee
    from public.workshops w
    where w.id = v_workshop_id;
  else
    select
      coalesce(nullif(trim(w.location_address), ''), 'Retiro en taller'),
      coalesce(nullif(trim(w.phone), ''), '')
    into v_workshop_address, v_workshop_phone
    from public.workshops w
    where w.id = v_workshop_id;
  end if;

  v_tax_total := round(v_products_total * public.cart_tax_rate(), 2);
  v_total_amount := v_products_total + v_tax_total + v_delivery_fee;

  v_order_number :=
    'CART-' ||
    to_char(now(), 'YYYYMMDD') ||
    '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.orders (
    order_number,
    workshop_id,
    customer_id,
    order_status,
    payment_status,
    payment_expires_at,
    total_amount,
    paid_amount,
    remaining_amount
  )
  values (
    v_order_number,
    v_workshop_id,
    v_customer_id,
    'pending',
    'unpaid',
    null,
    v_total_amount,
    0,
    v_total_amount
  )
  returning id into v_order_id;

  for v_product in
    select
      id,
      selling_price,
      quantity
    from jsonb_to_recordset(v_validated_products)
      as product_item(id uuid, selling_price numeric, quantity integer)
  loop
    update public.inventory_items
    set current_stock = coalesce(current_stock, 0) - v_product.quantity
    where id = v_product.id
      and coalesce(current_stock, 0) >= v_product.quantity;

    if not found then
      raise exception using message = 'cart_product_stock_unavailable';
    end if;

    insert into public.order_products (
      order_id,
      inventory_item_id,
      quantity,
      unit_price,
      product_status
    )
    values (
      v_order_id,
      v_product.id,
      v_product.quantity,
      v_product.selling_price,
      'pending'
    );
  end loop;

  insert into public.order_delivery_details (
    order_id,
    province,
    canton,
    district,
    exact_address,
    phone,
    delivery_fee,
    is_home_delivery,
    is_received
  )
  values (
    v_order_id,
    case when p_home_delivery then v_delivery_province else 'Retiro en taller' end,
    case when p_home_delivery then v_delivery_canton else 'Retiro en taller' end,
    case when p_home_delivery then v_delivery_district else 'Retiro en taller' end,
    case when p_home_delivery then v_delivery_exact_address else v_workshop_address end,
    case
      when p_home_delivery then v_delivery_phone
      else coalesce(nullif(trim(v_profile_phone), ''), v_workshop_phone)
    end,
    v_delivery_fee,
    p_home_delivery,
    false
  );

  return jsonb_build_object(
    'orderId', v_order_id,
    'orderNumber', v_order_number,
    'totalAmount', v_total_amount
  );
end;
$function$;

revoke all on function public.create_cart_order(jsonb, boolean, jsonb)
from public, anon, authenticated;

grant execute on function public.create_cart_order(jsonb, boolean, jsonb)
to authenticated;

notify pgrst, 'reload schema';
