alter table public.customer_delivery_addresses
add column if not exists created_at timestamptz not null default now(),
add column if not exists updated_at timestamptz not null default now(),
add column if not exists updated_by text;

create or replace function public.save_customer_delivery_address(
  p_address_id uuid default null,
  p_province text default '',
  p_canton text default '',
  p_district text default '',
  p_exact_address text default '',
  p_phone text default ''
)
returns public.customer_delivery_addresses
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid;
  v_address public.customer_delivery_addresses;
  v_normalized_province text := lower(regexp_replace(btrim(p_province), '\s+', ' ', 'g'));
  v_normalized_canton text := lower(regexp_replace(btrim(p_canton), '\s+', ' ', 'g'));
  v_normalized_district text := lower(regexp_replace(btrim(p_district), '\s+', ' ', 'g'));
  v_normalized_exact_address text := lower(regexp_replace(btrim(p_exact_address), '\s+', ' ', 'g'));
  v_normalized_phone text := lower(regexp_replace(btrim(p_phone), '\s+', ' ', 'g'));
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'cart_auth_required';
  end if;

  if v_normalized_province = ''
    or v_normalized_canton = ''
    or v_normalized_district = ''
    or v_normalized_exact_address = ''
    or v_normalized_phone = ''
  then
    raise exception 'cart_delivery_details_required';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('customer_delivery_addresses:' || v_user_id::text, 0)
  );

  if p_address_id is null then
    select *
    into v_address
    from public.customer_delivery_addresses cda
    where cda.user_id = v_user_id
      and cda.is_active = true
      and lower(regexp_replace(btrim(cda.province), '\s+', ' ', 'g')) =
        v_normalized_province
      and lower(regexp_replace(btrim(cda.canton), '\s+', ' ', 'g')) =
        v_normalized_canton
      and lower(regexp_replace(btrim(cda.district), '\s+', ' ', 'g')) =
        v_normalized_district
      and lower(regexp_replace(btrim(cda.exact_address), '\s+', ' ', 'g')) =
        v_normalized_exact_address
      and lower(regexp_replace(btrim(cda.phone), '\s+', ' ', 'g')) =
        v_normalized_phone
    order by cda.is_default desc
    limit 1
    for update;

    if v_address.id is not null then
      update public.customer_delivery_addresses
      set is_default = false
      where user_id = v_user_id
        and is_active = true
        and id <> v_address.id;

      update public.customer_delivery_addresses
      set
        is_default = true,
        province = btrim(p_province),
        canton = btrim(p_canton),
        district = btrim(p_district),
        exact_address = btrim(p_exact_address),
        phone = btrim(p_phone)
      where id = v_address.id
      returning * into v_address;

      return v_address;
    end if;

    update public.customer_delivery_addresses
    set is_default = false
    where user_id = v_user_id
      and is_active = true;

    insert into public.customer_delivery_addresses (
      user_id,
      province,
      canton,
      district,
      exact_address,
      phone,
      is_default,
      is_active
    )
    values (
      v_user_id,
      btrim(p_province),
      btrim(p_canton),
      btrim(p_district),
      btrim(p_exact_address),
      btrim(p_phone),
      true,
      true
    )
    returning * into v_address;
  else
    select *
    into v_address
    from public.customer_delivery_addresses
    where id = p_address_id
      and user_id = v_user_id
      and is_active = true
    for update;

    if v_address.id is null then
      raise exception 'cart_delivery_address_not_found';
    end if;

    update public.customer_delivery_addresses
    set is_default = false
    where user_id = v_user_id
      and is_active = true
      and id <> p_address_id;

    update public.customer_delivery_addresses
    set
      province = btrim(p_province),
      canton = btrim(p_canton),
      district = btrim(p_district),
      exact_address = btrim(p_exact_address),
      phone = btrim(p_phone),
      is_default = true,
      is_active = true
    where id = p_address_id
    returning * into v_address;
  end if;

  return v_address;
end;
$function$;

revoke all on function public.save_customer_delivery_address(
  uuid,
  text,
  text,
  text,
  text,
  text
) from public;

grant execute on function public.save_customer_delivery_address(
  uuid,
  text,
  text,
  text,
  text,
  text
) to authenticated;

create or replace function public.delete_customer_delivery_address(
  p_address_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid;
  v_was_default boolean;
  v_next_address_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'cart_auth_required';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('customer_delivery_addresses:' || v_user_id::text, 0)
  );

  select is_default
  into v_was_default
  from public.customer_delivery_addresses
  where id = p_address_id
    and user_id = v_user_id
    and is_active = true
  for update;

  if not found then
    return;
  end if;

  update public.customer_delivery_addresses
  set
    is_active = false,
    is_default = false
  where id = p_address_id
    and user_id = v_user_id;

  if v_was_default then
    select id
    into v_next_address_id
    from public.customer_delivery_addresses
    where user_id = v_user_id
      and is_active = true
    order by updated_at desc nulls last, created_at desc nulls last, id
    limit 1
    for update;

    if v_next_address_id is not null then
      update public.customer_delivery_addresses
      set is_default = true
      where id = v_next_address_id;
    end if;
  end if;
end;
$function$;

revoke all on function public.delete_customer_delivery_address(uuid)
from public, anon, authenticated;

grant execute on function public.delete_customer_delivery_address(uuid)
to authenticated;

notify pgrst, 'reload schema';
