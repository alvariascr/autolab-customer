alter table public.customer_locations
  add column if not exists country text not null default 'Costa Rica',
  add column if not exists province text not null default '',
  add column if not exists canton text not null default '',
  add column if not exists district text not null default '',
  add column if not exists exact_address text not null default '';
