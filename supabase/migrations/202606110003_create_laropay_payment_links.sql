create table if not exists public.laropay_payment_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  internal_transaction_id text not null,
  id_transaction integer not null,
  amount numeric(12, 2) not null,
  currency_code text not null,
  document text,
  detail text,
  customer_email text,
  expiration_type text not null,
  expiration_value integer not null,
  url_callback text,
  link_id text unique,
  link_url text,
  status text not null default 'created',
  response_code text,
  response_description text,
  reject_reason text,
  auth_response_code text,
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.laropay_payment_links enable row level security;

create index if not exists laropay_payment_links_user_id_idx
  on public.laropay_payment_links(user_id);

create index if not exists laropay_payment_links_internal_transaction_id_idx
  on public.laropay_payment_links(internal_transaction_id);

create unique index if not exists laropay_payment_links_active_transaction_idx
  on public.laropay_payment_links(user_id, internal_transaction_id)
  where status in ('created', 'pending');

create or replace function public.set_laropay_payment_links_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_laropay_payment_links_updated_at
  on public.laropay_payment_links;

create trigger set_laropay_payment_links_updated_at
before update on public.laropay_payment_links
for each row
execute function public.set_laropay_payment_links_updated_at();

drop policy if exists "customers can read own laropay links"
  on public.laropay_payment_links;

create policy "customers can read own laropay links"
  on public.laropay_payment_links
  for select
  to authenticated
  using (user_id = auth.uid());

revoke all on public.laropay_payment_links from public;
grant select on public.laropay_payment_links to authenticated;
grant all on public.laropay_payment_links to service_role;

notify pgrst, 'reload schema';
