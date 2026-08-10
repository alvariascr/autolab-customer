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
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'cart_auth_required';
  end if;

  if btrim(p_province) = ''
    or btrim(p_canton) = ''
    or btrim(p_district) = ''
    or btrim(p_exact_address) = ''
    or btrim(p_phone) = ''
  then
    raise exception 'cart_delivery_details_required';
  end if;

  if p_address_id is null then
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

create or replace function public.set_default_customer_delivery_address(
  p_address_id uuid
)
returns public.customer_delivery_addresses
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid;
  v_address public.customer_delivery_addresses;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'cart_auth_required';
  end if;

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
  set is_default = true
  where id = p_address_id
  returning * into v_address;

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

revoke all on function public.set_default_customer_delivery_address(uuid)
from public;

grant execute on function public.save_customer_delivery_address(
  uuid,
  text,
  text,
  text,
  text,
  text
) to authenticated;

grant execute on function public.set_default_customer_delivery_address(uuid)
to authenticated;
