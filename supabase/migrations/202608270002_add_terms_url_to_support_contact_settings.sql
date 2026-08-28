alter table public.support_contact_settings
  add column if not exists terms_url text not null
  default 'https://www.autolab.lat/terminos-y-condiciones/';

update public.support_contact_settings
set
  terms_url = 'https://www.autolab.lat/terminos-y-condiciones/',
  updated_at = now()
where terms_url is null or btrim(terms_url) = '';
