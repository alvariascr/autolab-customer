create or replace function public.sync_garage_vehicle_to_customer_vehicles()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_previous_plate text;
begin
  if not new.is_active then
    return new;
  end if;

  v_previous_plate := case
    when tg_op = 'UPDATE' then upper(trim(old.license_plate))
    else upper(trim(new.license_plate))
  end;

  update public.vehicles v
  set
    vehicle_type = coalesce(
      nullif(trim(coalesce(new.vehicle_type::text, '')), ''),
      v.vehicle_type
    ),
    brand = coalesce(nullif(trim(coalesce(new.brand, '')), ''), v.brand),
    model = coalesce(nullif(trim(coalesce(new.model, '')), ''), v.model),
    year = coalesce(new.year, v.year),
    color = coalesce(
      nullif(trim(coalesce(new.color::text, '')), ''),
      v.color
    ),
    fuel_type = coalesce(new.fuel_type, v.fuel_type),
    transmission_type = coalesce(
      new.transmission_type,
      v.transmission_type
    ),
    updated_at = now()
  from public.customers c
  where v.customer_id = c.id
    and c.user_id = new.user_id
    and upper(trim(v.license_plate)) = v_previous_plate;

  return new;
end;
$$;

revoke all
on function public.sync_garage_vehicle_to_customer_vehicles()
from public, anon, authenticated;

drop trigger if exists sync_garage_vehicle_to_customer_vehicles
on public.garage_vehicles;

create trigger sync_garage_vehicle_to_customer_vehicles
after insert or update of
  license_plate,
  vehicle_type,
  brand,
  model,
  year,
  color,
  fuel_type,
  transmission_type,
  is_active
on public.garage_vehicles
for each row
execute function public.sync_garage_vehicle_to_customer_vehicles();

update public.vehicles v
set
  vehicle_type = coalesce(
    nullif(trim(coalesce(gv.vehicle_type::text, '')), ''),
    v.vehicle_type
  ),
  brand = coalesce(nullif(trim(coalesce(gv.brand, '')), ''), v.brand),
  model = coalesce(nullif(trim(coalesce(gv.model, '')), ''), v.model),
  year = coalesce(gv.year, v.year),
  color = coalesce(
    nullif(trim(coalesce(gv.color::text, '')), ''),
    v.color
  ),
  fuel_type = coalesce(gv.fuel_type, v.fuel_type),
  transmission_type = coalesce(
    gv.transmission_type,
    v.transmission_type
  ),
  updated_at = now()
from public.customers c
join public.garage_vehicles gv
  on gv.user_id = c.user_id
 and gv.is_active = true
where v.customer_id = c.id
  and upper(trim(v.license_plate)) = upper(trim(gv.license_plate));
