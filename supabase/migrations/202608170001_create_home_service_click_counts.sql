create table if not exists public.home_service_click_counts (
  service_key text primary key,
  click_count bigint not null default 0 check (click_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.home_service_click_counts enable row level security;

drop policy if exists "authenticated users can read home service popularity"
on public.home_service_click_counts;

create policy "authenticated users can read home service popularity"
on public.home_service_click_counts
for select
to authenticated
using (true);

insert into public.home_service_click_counts (service_key)
values
  ('inspeccion'),
  ('cambio_aceite'),
  ('cambio_llanta'),
  ('balanceo'),
  ('alineamiento'),
  ('reparacion_llanta'),
  ('estetica_automotriz'),
  ('electrico'),
  ('instalacion'),
  ('aire_acondicionado'),
  ('grua'),
  ('llantas'),
  ('aceites'),
  ('repuestos'),
  ('coolant'),
  ('producto_auto_lavado'),
  ('luces'),
  ('baterias'),
  ('liquidos'),
  ('lubricantes'),
  ('quimicos'),
  ('aditivos'),
  ('grasas'),
  ('filtros'),
  ('tecnologia'),
  ('aros'),
  ('racks'),
  ('alfombras'),
  ('escobillas')
on conflict (service_key) do nothing;

create or replace function public.increment_home_service_click(
  p_service_key text
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_click_count bigint;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  update public.home_service_click_counts
  set
    click_count = click_count + 1,
    updated_at = now()
  where service_key = p_service_key
  returning click_count into v_click_count;

  if v_click_count is null then
    raise exception 'invalid home service key' using errcode = '22023';
  end if;

  return v_click_count;
end;
$$;

revoke all on function public.increment_home_service_click(text) from public;
revoke all on function public.increment_home_service_click(text) from anon;
grant execute on function public.increment_home_service_click(text) to authenticated;

grant select on table public.home_service_click_counts to authenticated;
