-- NÉP 008: configurable hotel, room and transport options for tour bookings.
-- The 3-star hotel + standard transport are the base package.
-- Premium surcharges remain NULL until confirmed by suppliers; never invent a payable price.

create table if not exists public.journey_service_options (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references public.journeys(id) on delete cascade,
  option_type text not null check (option_type in ('hotel','transport','room')),
  code text not null,
  name text not null,
  description text,
  price_delta_per_person integer,
  price_status text not null default 'quote_required'
    check (price_status in ('included','confirmed','quote_required')),
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (journey_id, option_type, code),
  check (price_delta_per_person is null or price_delta_per_person >= 0),
  check (
    (price_status = 'quote_required' and price_delta_per_person is null)
    or (price_status in ('included','confirmed') and price_delta_per_person is not null)
  )
);

alter table public.bookings
  add column if not exists journey_id uuid references public.journeys(id) on delete set null,
  add column if not exists departure_id uuid references public.journey_departures(id) on delete set null,
  add column if not exists hotel_option_id uuid references public.journey_service_options(id) on delete set null,
  add column if not exists transport_option_id uuid references public.journey_service_options(id) on delete set null,
  add column if not exists room_option_id uuid references public.journey_service_options(id) on delete set null,
  add column if not exists quoted_price_per_person integer,
  add column if not exists quoted_total integer,
  add column if not exists quote_status text not null default 'pending'
    check (quote_status in ('pending','priced','confirmed'));

alter table public.journey_service_options enable row level security;

drop policy if exists "Public can view active journey service options" on public.journey_service_options;
create policy "Public can view active journey service options"
on public.journey_service_options for select
using (
  is_active = true
  and exists (
    select 1 from public.journeys j
    where j.id = journey_service_options.journey_id
      and j.is_published = true
  )
);

drop policy if exists "Admins manage journey service options" on public.journey_service_options;
create policy "Admins manage journey service options"
on public.journey_service_options for all
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Seed the included base choices for all ten curated tours.
-- Multi-day tours receive a 3-star hotel and standard room baseline.
insert into public.journey_service_options
  (journey_id, option_type, code, name, description, price_delta_per_person, price_status, is_default)
select j.id, 'hotel', 'hotel_3_star', 'Khách sạn 3 sao',
       'Hạng lưu trú tiêu chuẩn đã tính trong giá cơ bản.', 0, 'included', true
from public.journeys j
where j.duration_days > 1
on conflict (journey_id, option_type, code) do nothing;

insert into public.journey_service_options
  (journey_id, option_type, code, name, description, price_delta_per_person, price_status, is_default)
select j.id, 'room', 'standard_room', 'Phòng tiêu chuẩn',
       'Loại phòng cơ bản; cách bố trí giường xác nhận theo số khách.', 0, 'included', true
from public.journeys j
where j.duration_days > 1
on conflict (journey_id, option_type, code) do nothing;

insert into public.journey_service_options
  (journey_id, option_type, code, name, description, price_delta_per_person, price_status, is_default)
select j.id, 'transport', 'standard_transport', 'Phương tiện tiêu chuẩn',
       coalesce(j.transport, 'Phương tiện theo chương trình') || '. Đã tính trong giá cơ bản.',
       0, 'included', true
from public.journeys j
on conflict (journey_id, option_type, code) do nothing;

-- Premium choices are selectable but require NÉP to confirm the supplier surcharge.
insert into public.journey_service_options
  (journey_id, option_type, code, name, description, price_delta_per_person, price_status, is_default)
select j.id, 'hotel', v.code, v.name, v.description, null, 'quote_required', false
from public.journeys j
cross join (values
  ('hotel_4_star', 'Khách sạn 4 sao', 'Nâng hạng lưu trú; phụ thu xác nhận theo ngày và điểm đến.'),
  ('hotel_5_star', 'Khách sạn 5 sao', 'Nâng hạng lưu trú; phụ thu xác nhận theo ngày và điểm đến.')
) as v(code, name, description)
where j.duration_days > 1
on conflict (journey_id, option_type, code) do nothing;

insert into public.journey_service_options
  (journey_id, option_type, code, name, description, price_delta_per_person, price_status, is_default)
select j.id, 'transport', v.code, v.name, v.description, null, 'quote_required', false
from public.journeys j
cross join (values
  ('transport_comfort', 'Xe chất lượng cao / limousine', 'Nâng cấp theo tuyến; cần xác nhận phương tiện thực tế.'),
  ('transport_flight_business', 'Máy bay hạng thương gia (nếu có)', 'Chỉ áp dụng tuyến có chặng bay; phụ thuộc hãng và chỗ.')
) as v(code, name, description)
on conflict (journey_id, option_type, code) do nothing;

comment on table public.journey_service_options is
  'Tour options. NULL surcharge means supplier quote is required; it must not be treated as zero.';
