create or replace function public.set_customer_favorites_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at = now();
  new.updated_by = coalesce(auth.uid()::text, new.updated_by);
  return new;
end;
$function$;

create or replace function public.set_customer_locations_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

drop trigger if exists set_customer_locations_updated_at
on public.customer_locations;

create trigger set_customer_locations_updated_at
before update on public.customer_locations
for each row
execute function public.set_customer_locations_updated_at();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'customer_locations_latitude_range_check'
  ) then
    alter table public.customer_locations
      add constraint customer_locations_latitude_range_check
      check (latitude between -90 and 90);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'customer_locations_longitude_range_check'
  ) then
    alter table public.customer_locations
      add constraint customer_locations_longitude_range_check
      check (longitude between -180 and 180);
  end if;
end;
$$;

create or replace function public.set_support_contact_settings_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

drop trigger if exists set_support_contact_settings_updated_at
on public.support_contact_settings;

create trigger set_support_contact_settings_updated_at
before update on public.support_contact_settings
for each row
execute function public.set_support_contact_settings_updated_at();

grant select on public.support_contact_settings to anon, authenticated;
grant insert, update, delete on public.support_contact_settings to authenticated;

drop policy if exists "Admins can manage support contact settings"
  on public.support_contact_settings;

create policy "Admins can manage support contact settings"
on public.support_contact_settings
for all
to authenticated
using (
  exists (
    select 1
    from public.user_profiles
    where id = auth.uid()
      and role = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.user_profiles
    where id = auth.uid()
      and role = 'admin'
  )
);
