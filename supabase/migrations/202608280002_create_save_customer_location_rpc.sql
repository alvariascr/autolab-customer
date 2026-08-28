create or replace function public.save_customer_location(
  p_location_id uuid default null,
  p_label text default '',
  p_address text default '',
  p_country text default 'Costa Rica',
  p_province text default '',
  p_canton text default '',
  p_district text default '',
  p_exact_address text default '',
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns public.customer_locations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_location public.customer_locations;
  v_should_be_default boolean;
begin
  if v_user_id is null then
    raise exception 'location_auth_required';
  end if;

  if nullif(trim(p_address), '') is null then
    raise exception 'location_address_required';
  end if;

  if p_latitude is null
    or p_longitude is null
    or p_latitude < -90
    or p_latitude > 90
    or p_longitude < -180
    or p_longitude > 180 then
    raise exception 'location_coordinates_invalid';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));

  if p_location_id is null then
    select not exists (
      select 1
      from public.customer_locations
      where user_id = v_user_id
        and is_active = true
        and is_default = true
    )
    into v_should_be_default;

    insert into public.customer_locations (
      user_id,
      label,
      address,
      country,
      province,
      canton,
      district,
      exact_address,
      latitude,
      longitude,
      is_default,
      is_active
    )
    values (
      v_user_id,
      trim(coalesce(p_label, '')),
      trim(p_address),
      trim(coalesce(p_country, 'Costa Rica')),
      trim(coalesce(p_province, '')),
      trim(coalesce(p_canton, '')),
      trim(coalesce(p_district, '')),
      trim(coalesce(p_exact_address, '')),
      p_latitude,
      p_longitude,
      v_should_be_default,
      true
    )
    returning * into v_location;
  else
    update public.customer_locations
    set
      label = trim(coalesce(p_label, '')),
      address = trim(p_address),
      country = trim(coalesce(p_country, 'Costa Rica')),
      province = trim(coalesce(p_province, '')),
      canton = trim(coalesce(p_canton, '')),
      district = trim(coalesce(p_district, '')),
      exact_address = trim(coalesce(p_exact_address, '')),
      latitude = p_latitude,
      longitude = p_longitude,
      updated_at = now()
    where id = p_location_id
      and user_id = v_user_id
      and is_active = true
    returning * into v_location;

    if v_location.id is null then
      raise exception 'location_not_found';
    end if;
  end if;

  return v_location;
end;
$$;

grant execute on function public.save_customer_location(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  double precision,
  double precision
) to authenticated;
