-- NÉP tour catalogue: operational details and scheduled departures.
-- Apply after 002_journey_memory_schema.sql. Existing journeys remain intact.
-- Publish only after each itinerary, price and operating schedule has been verified.

alter table public.journeys
  add column if not exists tour_type text not null default 'Trải nghiệm địa phương',
  add column if not exists duration_days integer not null default 1 check (duration_days > 0),
  add column if not exists duration_label text not null default '1 ngày',
  add column if not exists departure_point text not null default '',
  add column if not exists meeting_time time,
  add column if not exists expected_return_time time,
  add column if not exists transport text not null default '',
  add column if not exists inclusions text[] not null default '{}',
  add column if not exists exclusions text[] not null default '{}',
  add column if not exists price_note text not null default 'Giá tham khảo; xác nhận trước khi đặt',
  add column if not exists min_guests integer not null default 1 check (min_guests > 0),
  add column if not exists max_guests integer check (max_guests is null or max_guests >= min_guests),
  add column if not exists itinerary jsonb not null default '[]'::jsonb,
  add column if not exists operating_note text not null default '',
  add column if not exists verified_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.journey_departures (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  departure_date date not null,
  start_time time,
  end_time time,
  price_per_person integer not null check (price_per_person >= 0),
  currency text not null default 'VND' check (currency = 'VND'),
  capacity integer not null check (capacity > 0),
  booked_count integer not null default 0 check (booked_count >= 0 and booked_count <= capacity),
  status text not null default 'scheduled'
    check (status in ('scheduled','full','cancelled','completed')),
  booking_deadline timestamptz,
  operating_note text not null default '',
  created_at timestamptz not null default now(),
  unique (journey_id, departure_date)
);

alter table public.journey_departures enable row level security;

create policy "Public view departures of published journeys"
on public.journey_departures for select to anon, authenticated
using (
  exists (
    select 1 from public.journeys j
    where j.id = journey_id and j.is_published = true
  ) or public.is_admin()
);

create policy "Admins manage journey departures"
on public.journey_departures for all to authenticated
using (public.is_admin()) with check (public.is_admin());

grant select on public.journey_departures to anon, authenticated;
grant select, insert, update, delete on public.journey_departures to authenticated;

-- The public catalogue must not expose drafts; admins retain full management access.
-- Existing 002 policies already protect journey rows with is_published / is_admin.
