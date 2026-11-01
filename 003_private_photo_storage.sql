-- Private storage for NÉP customer journey photos.
-- Run once in Supabase SQL Editor after 002_journey_memory_schema.sql.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'nep-journey-photos',
  'nep-journey-photos',
  false,
  10485760,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Customers upload photos to own folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'nep-journey-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Customers read own photos"
on storage.objects for select to authenticated
using (
  bucket_id = 'nep-journey-photos'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

create policy "Customers delete own photos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'nep-journey-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Customers update own photos"
on storage.objects for update to authenticated
using (
  bucket_id = 'nep-journey-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'nep-journey-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
