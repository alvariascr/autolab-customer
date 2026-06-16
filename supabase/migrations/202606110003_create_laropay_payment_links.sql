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
  expires_at timestamptz not null,
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
  updated_at timestamptz not null default now(),
  constraint laropay_payment_links_amount_positive check (amount > 0),
  constraint laropay_payment_links_currency_code_check check (
    currency_code in ('CRC', 'USD')
  ),
  constraint laropay_payment_links_expiration_type_check check (
    expiration_type in ('D', 'H', 'M')
  ),
  constraint laropay_payment_links_expiration_value_positive check (
    expiration_value > 0
  )
);

alter table public.laropay_payment_links enable row level security;

alter table public.laropay_payment_links
  add column if not exists expires_at timestamptz;

update public.laropay_payment_links
set expires_at = created_at +
  case expiration_type
    when 'H' then make_interval(hours => expiration_value)
    when 'M' then make_interval(mins => expiration_value)
    else make_interval(days => expiration_value)
  end
where expires_at is null;

alter table public.laropay_payment_links
  alter column expires_at set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'laropay_payment_links_amount_positive'
  ) then
    alter table public.laropay_payment_links
      add constraint laropay_payment_links_amount_positive check (amount > 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'laropay_payment_links_currency_code_check'
  ) then
    alter table public.laropay_payment_links
      add constraint laropay_payment_links_currency_code_check check (
        currency_code in ('CRC', 'USD')
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'laropay_payment_links_expiration_type_check'
  ) then
    alter table public.laropay_payment_links
      add constraint laropay_payment_links_expiration_type_check check (
        expiration_type in ('D', 'H', 'M')
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'laropay_payment_links_expiration_value_positive'
  ) then
    alter table public.laropay_payment_links
      add constraint laropay_payment_links_expiration_value_positive check (
        expiration_value > 0
      );
  end if;
end;
$$;

create index if not exists laropay_payment_links_user_id_idx
  on public.laropay_payment_links(user_id);

create index if not exists laropay_payment_links_internal_transaction_id_idx
  on public.laropay_payment_links(internal_transaction_id);

create index if not exists laropay_payment_links_expires_at_idx
  on public.laropay_payment_links(expires_at);

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
