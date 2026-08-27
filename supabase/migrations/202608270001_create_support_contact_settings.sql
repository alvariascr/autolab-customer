create table if not exists public.support_contact_settings (
  id uuid primary key default gen_random_uuid(),
  whatsapp_phone text not null,
  call_phone text not null,
  email text not null,
  schedule_text text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists support_contact_settings_active_updated_idx
  on public.support_contact_settings (is_active, updated_at desc);

alter table public.support_contact_settings enable row level security;

drop policy if exists "Anyone can read active support contact settings"
  on public.support_contact_settings;

create policy "Anyone can read active support contact settings"
  on public.support_contact_settings
  for select
  using (is_active = true);

insert into public.support_contact_settings (
  whatsapp_phone,
  call_phone,
  email,
  schedule_text,
  is_active
)
select
  '89147371',
  '89147371',
  'info@autolab.lat',
  'Lunes a viernes' || chr(10) || '7:00 a. m. - 5:00 p. m.',
  true
where not exists (
  select 1
  from public.support_contact_settings
  where is_active = true
);
