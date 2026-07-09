alter table public.laropay_payment_links
  add column if not exists status_checked_at timestamptz,
  add column if not exists verify_payload jsonb not null default '{}'::jsonb,
  add column if not exists certifier_payload jsonb not null default '{}'::jsonb,
  add column if not exists status_check_error text;

create index if not exists laropay_payment_links_status_checked_at_idx
  on public.laropay_payment_links(status_checked_at);

create index if not exists laropay_payment_links_pending_status_idx
  on public.laropay_payment_links(user_id, status, status_checked_at)
  where status in ('created', 'pending');

notify pgrst, 'reload schema';
