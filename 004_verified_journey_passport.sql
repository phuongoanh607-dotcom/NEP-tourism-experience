-- NÉP Journey Passport: booking-bound QR check-ins and verified certificates.
-- Apply after 002_journey_memory_schema.sql in Supabase SQL Editor.

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
grant select, insert, update, delete on public.journey_checkins to authenticated;

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
  v_checkin_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập để check-in.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and user_id = auth.uid();

  if not found then
    raise exception 'Không tìm thấy booking thuộc tài khoản của bạn.';
  end if;

  if v_booking.status not in ('confirmed','completed') then
    raise exception 'Booking cần được xác nhận trước khi check-in.';
  end if;

  select s.* into v_stop
  from public.journey_stops s
  join public.journeys j on j.id = s.journey_id
  where s.qr_token = p_token
    and s.journey_id = v_booking.journey_id
    and j.is_published = true;

  if not found then
    raise exception 'QR không thuộc hành trình trong booking này.';
  end if;

  insert into public.journey_checkins(user_id, booking_id, journey_id, journey_stop_id)
  values (auth.uid(), v_booking.id, v_booking.journey_id, v_stop.id)
  on conflict (booking_id, journey_stop_id) do nothing
  returning id into v_checkin_id;

  if v_checkin_id is null then
    return jsonb_build_object(
      'message', 'Điểm dừng này đã được ghi nhận trước đó.',
      'stop_name', v_stop.title,
      'already_checked_in', true
    );
  end if;

  return jsonb_build_object(
    'message', 'Check-in hành trình thành công!',
    'stop_name', v_stop.title,
    'already_checked_in', false
  );
end;
$$;

grant execute on function public.redeem_journey_stop_qr(uuid, uuid) to authenticated;

create or replace function public.issue_journey_certificate(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_required integer;
  v_completed integer;
  v_certificate public.journey_certificates%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and user_id = auth.uid();

  if not found then
    raise exception 'Không tìm thấy booking thuộc tài khoản của bạn.';
  end if;

  if v_booking.status <> 'completed' then
    raise exception 'Booking phải được quản trị viên xác nhận hoàn thành trước khi cấp chứng nhận.';
  end if;

  if v_booking.journey_id is null then
    raise exception 'Booking này chưa gắn với hành trình NÉP.';
  end if;

  select count(*) into v_required
  from public.journey_stops
  where journey_id = v_booking.journey_id and is_required = true;

  if v_required = 0 then
    raise exception 'Hành trình chưa có điểm dừng bắt buộc.';
  end if;

  select count(*) into v_completed
  from public.journey_checkins c
  join public.journey_stops s on s.id = c.journey_stop_id
  where c.booking_id = v_booking.id
    and c.user_id = auth.uid()
    and s.journey_id = v_booking.journey_id
    and s.is_required = true;

  if v_completed < v_required then
    raise exception 'Bạn chưa check-in đủ các điểm dừng bắt buộc (%/%).', v_completed, v_required;
  end if;

  insert into public.journey_certificates(user_id, booking_id, journey_id)
  values (auth.uid(), v_booking.id, v_booking.journey_id)
  on conflict (booking_id) do nothing;

  select * into v_certificate
  from public.journey_certificates
  where booking_id = v_booking.id;

  return jsonb_build_object(
    'certificate_id', v_certificate.id,
    'certificate_code', v_certificate.certificate_code,
    'issued_at', v_certificate.issued_at,
    'journey_id', v_certificate.journey_id
  );
end;
$$;

grant execute on function public.issue_journey_certificate(uuid) to authenticated;
