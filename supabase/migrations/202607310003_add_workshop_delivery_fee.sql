alter table public.workshops
add column if not exists delivery_fee numeric not null default 0;
