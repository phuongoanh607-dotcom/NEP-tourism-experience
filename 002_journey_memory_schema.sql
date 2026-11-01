-- NÉP additive data model for the customer journey and Memory Capsule.
-- This migration does not delete or rewrite existing records.

create table if not exists public.journeys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  region text not null,
  summary text not null default '',
  duration text,
  price_from integer not null default 0 check (price_from >= 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.journey_stops (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  place_id uuid references public.places(id) on delete set null,
  title text not null,
  stop_order integer not null check (stop_order > 0),
  is_required boolean not null default true,
  qr_token uuid not null default gen_random_uuid() unique,
  created_at timestamptz not null default now(),
  unique (journey_id, stop_order)
);

alter table public.bookings
  add column if not exists journey_id uuid references public.journeys(id) on delete set null;

alter table public.checkins
  add column if not exists booking_id uuid references public.bookings(id) on delete cascade;
alter table public.checkins
  add column if not exists journey_stop_id uuid references public.journey_stops(id) on delete cascade;

create table if not exists public.journey_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  journey_id uuid not null references public.journeys(id) on delete cascade,
  journey_stop_id uuid references public.journey_stops(id) on delete set null,
  storage_path text not null unique,
  caption text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.journey_certificates (
  id uuid primary key default gen_random_uuid(),
  certificate_code text not null unique default ('NEP-' || upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  user_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  journey_id uuid not null references public.journeys(id) on delete cascade,
  issued_at timestamptz not null default now()
);

alter table public.journeys enable row level security;
alter table public.journey_stops enable row level security;
alter table public.journey_photos enable row level security;
alter table public.journey_certificates enable row level security;

create policy "Public can view published journeys"
  on public.journeys for select to anon, authenticated
  using (is_published = true or public.is_admin());
create policy "Admins manage journeys"
  on public.journeys for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "Public can view stops of published journeys"
  on public.journey_stops for select to anon, authenticated
  using (exists (
    select 1 from public.journeys j
    where j.id = journey_id and j.is_published = true
  ) or public.is_admin());
create policy "Admins manage journey stops"
  on public.journey_stops for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "Customers view own journey photos"
  on public.journey_photos for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "Customers add own journey photos"
  on public.journey_photos for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid()
        and b.journey_id = journey_id
    )
  );
create policy "Customers delete own journey photos"
  on public.journey_photos for delete to authenticated
  using (user_id = auth.uid());

create policy "Customers view own journey certificates"
  on public.journey_certificates for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "Admins manage journey certificates"
  on public.journey_certificates for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.journeys, public.journey_stops to anon, authenticated;
grant select, insert, update, delete on public.journeys, public.journey_stops,
  public.journey_photos, public.journey_certificates to authenticated;
