alter table public.garage_vehicles
add column if not exists is_default boolean not null default false;

with ranked_vehicles as (
  select
    id,
    row_number() over (
      partition by user_id
      order by updated_at desc nulls last, id
    ) as position
  from public.garage_vehicles
  where is_active = true
)
update public.garage_vehicles as garage_vehicle
set is_default = true
from ranked_vehicles
where garage_vehicle.id = ranked_vehicles.id
  and ranked_vehicles.position = 1
  and not exists (
    select 1
    from public.garage_vehicles as current_default
    where current_default.user_id = garage_vehicle.user_id
      and current_default.is_active = true
      and current_default.is_default = true
  );

create unique index if not exists garage_vehicles_one_default_per_user
on public.garage_vehicles (user_id)
where is_default = true and is_active = true;

create or replace function public.set_default_garage_vehicle(
  p_garage_vehicle_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'authentication_required';
  end if;

  perform 1
  from public.garage_vehicles
  where user_id = v_user_id
    and is_active = true
  for update;

  if not exists (
    select 1
    from public.garage_vehicles
    where id = p_garage_vehicle_id
      and user_id = v_user_id
      and is_active = true
  ) then
    raise exception 'garage_vehicle_not_found_or_not_owned';
  end if;

  if exists (
    select 1
    from public.garage_vehicles
    where id = p_garage_vehicle_id
      and user_id = v_user_id
      and is_active = true
      and is_default = true
  ) then
    return;
  end if;

  update public.garage_vehicles
  set is_default = false,
      updated_at = now()
  where user_id = v_user_id
    and is_active = true
    and is_default = true;

  update public.garage_vehicles
  set is_default = true,
      updated_at = now()
  where id = p_garage_vehicle_id
    and user_id = v_user_id
    and is_active = true;
end;
$$;

revoke all
on function public.set_default_garage_vehicle(uuid)
from public, anon, authenticated;

grant execute
on function public.set_default_garage_vehicle(uuid)
to authenticated;

notify pgrst, 'reload schema';
