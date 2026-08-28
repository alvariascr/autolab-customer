create table if not exists public.customer_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default '',
  address text not null,
  country text not null default 'Costa Rica',
  province text not null default '',
  canton text not null default '',
  district text not null default '',
  exact_address text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists customer_locations_user_active_idx
  on public.customer_locations (user_id, is_active, is_default desc, updated_at desc);

create unique index if not exists customer_locations_one_default_active_idx
  on public.customer_locations (user_id)
  where is_active = true and is_default = true;

alter table public.customer_locations enable row level security;

drop policy if exists "Customers can read their locations"
  on public.customer_locations;

create policy "Customers can read their locations"
  on public.customer_locations
  for select
  using (auth.uid() = user_id);

drop policy if exists "Customers can insert their locations"
  on public.customer_locations;

create policy "Customers can insert their locations"
  on public.customer_locations
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Customers can update their locations"
  on public.customer_locations;

create policy "Customers can update their locations"
  on public.customer_locations
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
