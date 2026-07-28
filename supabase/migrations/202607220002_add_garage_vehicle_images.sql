alter table public.garage_vehicles
add column if not exists image_path text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'garage-vehicle-images',
  'garage-vehicle-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "garage vehicle images select own" on storage.objects;
create policy "garage vehicle images select own"
on storage.objects for select
to authenticated
using (
  bucket_id = 'garage-vehicle-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "garage vehicle images insert own" on storage.objects;
create policy "garage vehicle images insert own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'garage-vehicle-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "garage vehicle images update own" on storage.objects;
create policy "garage vehicle images update own"
on storage.objects for update
to authenticated
using (
  bucket_id = 'garage-vehicle-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'garage-vehicle-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "garage vehicle images delete own" on storage.objects;
create policy "garage vehicle images delete own"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'garage-vehicle-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

notify pgrst, 'reload schema';
