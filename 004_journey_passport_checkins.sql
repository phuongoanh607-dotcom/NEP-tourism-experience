-- NÉP Journey Passport: booking-bound check-ins and server-validated completion.
-- Apply after 001_initial_schema.sql and 002_journey_memory_schema.sql.

create table if not exists public.journey_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  journey_id uuid not null references public.journeys(id) on delete cascade,
  journey_stop_id uuid not null references public.journey_stops(id) on delete cascade,
  checked_in_at timestamptz not null default now(),
  unique (booking_id, journey_stop_id)
);

alter table public.journey_checkins enable row level security;

create policy "Customers view own journey checkins"
on public.journey_checkins for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "Admins view all journey checkins"
on public.journey_checkins for all to authenticated
using (public.is_admin()) with check (public.is_admin());

grant select on public.journey_checkins to authenticated;

create or replace function public.redeem_journey_stop_qr(
  p_token uuid,
  p_booking_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_stop public.journey_stops%rowtype;
  v_done integer;
  v_required integer;
  v_certificate_id uuid;
  v_inserted integer;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập để check-in.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and user_id = auth.uid()
    and status in ('confirmed', 'completed')
  for update;

  if not found then
    raise exception 'Không tìm thấy booking hợp lệ của bạn.';
  end if;

  if v_booking.journey_id is null then
    raise exception 'Booking này chưa được gắn với hành trình NÉP.';
  end if;

  select * into v_stop
  from public.journey_stops
  where qr_token = p_token and journey_id = v_booking.journey_id;

  if not found then
    raise exception 'QR không thuộc hành trình trong booking này.';
  end if;

  insert into public.journey_checkins(user_id, booking_id, journey_id, journey_stop_id)
  values (auth.uid(), v_booking.id, v_booking.journey_id, v_stop.id)
  on conflict (booking_id, journey_stop_id) do nothing;

  select count(*) into v_done
  from public.journey_checkins
  where booking_id = v_booking.id;

  select count(*) into v_required
  from public.journey_stops
  where journey_id = v_booking.journey_id and is_required = true;

  if v_required > 0 and v_done >= v_required then
    insert into public.journey_certificates(user_id, booking_id, journey_id)
    values (auth.uid(), v_booking.id, v_booking.journey_id)
    on conflict (booking_id) do nothing
    returning id into v_certificate_id;

    if v_certificate_id is null then
      select id into v_certificate_id
      from public.journey_certificates
      where booking_id = v_booking.id;
    end if;
  end if;

  return jsonb_build_object(
    'message', 'Đã ghi nhận dấu mốc hành trình.',
    'place_name', v_stop.title,
    'already_checked_in', not found,
    'completed', (v_required > 0 and v_done >= v_required),
    'checked_in_count', v_done,
    'required_count', v_required,
    'certificate_id', v_certificate_id
  );
end;
$$;

revoke all on function public.redeem_journey_stop_qr(uuid, uuid) from public, anon;
grant execute on function public.redeem_journey_stop_qr(uuid, uuid) to authenticated;
