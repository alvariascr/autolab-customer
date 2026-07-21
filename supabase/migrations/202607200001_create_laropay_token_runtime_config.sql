create table if not exists public.laropay_runtime_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now(),
  constraint laropay_runtime_config_key_check check (key in ('token')),
  constraint laropay_runtime_config_value_not_blank check (btrim(value) <> '')
);

alter table public.laropay_runtime_config enable row level security;

revoke all on public.laropay_runtime_config from public, anon, authenticated;
grant all on public.laropay_runtime_config to service_role;

create table if not exists public.laropay_token_refresh_audit (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  status text not null,
  response_code text,
  response_description text,
  error_code text,
  created_at timestamptz not null default now(),
  constraint laropay_token_refresh_audit_status_check check (
    status in ('succeeded', 'failed')
  ),
  constraint laropay_token_refresh_audit_source_not_blank check (btrim(source) <> '')
);

alter table public.laropay_token_refresh_audit enable row level security;

create index if not exists laropay_token_refresh_audit_created_at_idx
  on public.laropay_token_refresh_audit(created_at desc);

revoke all on public.laropay_token_refresh_audit from public, anon, authenticated;
grant insert, select on public.laropay_token_refresh_audit to service_role;

notify pgrst, 'reload schema';
