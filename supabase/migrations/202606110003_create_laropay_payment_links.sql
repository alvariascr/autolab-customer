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

create index if not exists laropay_payment_links_user_id_idx
  on public.laropay_payment_links(user_id);

create index if not exists laropay_payment_links_internal_transaction_id_idx
  on public.laropay_payment_links(internal_transaction_id);

create index if not exists laropay_payment_links_expires_at_idx
  on public.laropay_payment_links(expires_at);

create unique index if not exists laropay_payment_links_active_transaction_idx
  on public.laropay_payment_links(user_id, internal_transaction_id)
  where status in ('created', 'pending');

create or replace function public.reserve_laropay_payment_link(
  p_user_id uuid,
  p_internal_transaction_id text,
  p_id_transaction integer,
  p_amount numeric,
  p_currency_code text,
  p_document text,
  p_detail text,
  p_customer_email text,
  p_expiration_type text,
  p_expiration_value integer,
  p_expires_at timestamptz,
  p_url_callback text,
  p_request_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing record;
  v_reserved_id uuid;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(p_user_id::text || ':' || p_internal_transaction_id, 0)
  );

  update public.laropay_payment_links
  set status = 'expired'
  where user_id = p_user_id
    and internal_transaction_id = p_internal_transaction_id
    and status in ('created', 'pending')
    and expires_at <= now();

  select id,
         link_id,
         link_url,
         status,
         response_code,
         response_description,
         reject_reason,
         auth_response_code
  into v_existing
  from public.laropay_payment_links
  where user_id = p_user_id
    and internal_transaction_id = p_internal_transaction_id
    and status in ('created', 'pending')
    and expires_at > now()
  order by created_at desc
  limit 1;

  if found then
    if coalesce(v_existing.link_id, '') <> ''
       and coalesce(v_existing.link_url, '') <> '' then
      return jsonb_build_object(
        'kind', 'existing',
        'link', to_jsonb(v_existing)
      );
    end if;

    return jsonb_build_object('kind', 'in_progress');
  end if;

  insert into public.laropay_payment_links (
    user_id,
    internal_transaction_id,
    id_transaction,
    amount,
    currency_code,
    document,
    detail,
    customer_email,
    expiration_type,
    expiration_value,
    expires_at,
    url_callback,
    status,
    request_payload
  )
  values (
    p_user_id,
    p_internal_transaction_id,
    p_id_transaction,
    p_amount,
    p_currency_code,
    p_document,
    p_detail,
    p_customer_email,
    p_expiration_type,
    p_expiration_value,
    p_expires_at,
    p_url_callback,
    'pending',
    p_request_payload
  )
  returning id into v_reserved_id;

  return jsonb_build_object('kind', 'reserved', 'id', v_reserved_id);
end;
$$;

revoke all on function public.reserve_laropay_payment_link(
  uuid,
  text,
  integer,
  numeric,
  text,
  text,
  text,
  text,
  text,
  integer,
  timestamptz,
  text,
  jsonb
) from public;

grant execute on function public.reserve_laropay_payment_link(
  uuid,
  text,
  integer,
  numeric,
  text,
  text,
  text,
  text,
  text,
  integer,
  timestamptz,
  text,
  jsonb
) to service_role;

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
