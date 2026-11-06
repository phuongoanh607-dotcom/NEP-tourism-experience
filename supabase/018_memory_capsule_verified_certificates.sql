-- NÉP Memory Capsule v2: booking-linked postcards and verified certificates.
-- Additive migration. Keeps existing memories and photo records intact.
-- Apply in Supabase SQL Editor after 017_customer_journey_completion_certificate.sql.

alter table public.memories
  add column if not exists booking_id uuid references public.bookings(id) on delete set null,
  add column if not exists journey_photo_id uuid references public.journey_photos(id) on delete set null;

create index if not exists memories_booking_created_idx
  on public.memories (booking_id, created_at desc);

-- Replace the permissive insert policy so a postcard can only reference
-- a booking and/or photo owned by the signed-in customer.
drop policy if exists "create own memories" on public.memories;
create policy "create own booking-linked memories"
on public.memories for insert to authenticated
with check (
  user_id = auth.uid()
  and (
    booking_id is null
    or exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid()
    )
  )
  and (
    journey_photo_id is null
    or exists (
      select 1 from public.journey_photos p
      where p.id = journey_photo_id
        and p.user_id = auth.uid()
        and (booking_id is null or p.booking_id = booking_id)
    )
  )
);

-- Completion is not self-attested by clicking a button and does not depend on
-- uploading photos. NÉP staff must mark the booking completed. If the tour has
-- required stops, every required stop must have a real booking-bound QR check-in.
create or replace function public.customer_complete_journey(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_certificate public.journey_certificates%rowtype;
  v_required integer;
  v_checked integer;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập để xem chứng nhận hành trình.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'Không tìm thấy booking thuộc tài khoản của bạn.';
  end if;

  if v_booking.journey_id is null then
    raise exception 'Booking này chưa được gắn với hành trình NÉP.';
  end if;

  if v_booking.status <> 'completed' then
    raise exception 'NÉP chưa xác nhận booking hoàn thành. Ảnh không thay thế bước xác nhận này.';
  end if;

  select count(*) into v_required
  from public.journey_stops
  where journey_id = v_booking.journey_id and is_required = true;

  select count(*) into v_checked
  from public.journey_checkins c
  join public.journey_stops s on s.id = c.journey_stop_id
  where c.booking_id = v_booking.id
    and c.user_id = auth.uid()
    and c.journey_id = v_booking.journey_id
    and s.is_required = true;

  if v_checked < v_required then
    raise exception 'Chưa đủ check-in QR bắt buộc: %/% điểm.', v_checked, v_required;
  end if;

  insert into public.journey_certificates(user_id, booking_id, journey_id)
  values (auth.uid(), v_booking.id, v_booking.journey_id)
  on conflict (booking_id) do nothing;

  select * into v_certificate
  from public.journey_certificates
  where booking_id = v_booking.id and user_id = auth.uid();

  return jsonb_build_object(
    'certificate_id', v_certificate.id,
    'certificate_code', v_certificate.certificate_code,
    'issued_at', v_certificate.issued_at,
    'journey_id', v_certificate.journey_id,
    'checked_in_count', v_checked,
    'required_count', v_required
  );
end;
$$;

revoke all on function public.customer_complete_journey(uuid) from public;
grant execute on function public.customer_complete_journey(uuid) to authenticated;
