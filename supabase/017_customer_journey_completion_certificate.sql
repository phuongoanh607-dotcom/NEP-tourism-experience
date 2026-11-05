-- Customer-confirmed journey completion and automatic certificate issuance.
-- Apply in Supabase SQL Editor after migration 016.

create or replace function public.customer_complete_journey(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_certificate public.journey_certificates%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập để xác nhận hoàn thành hành trình.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
    and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'Không tìm thấy booking thuộc tài khoản của bạn.';
  end if;

  if v_booking.journey_id is null then
    raise exception 'Booking này chưa được gắn với hành trình NÉP.';
  end if;

  if v_booking.status not in ('confirmed', 'completed') then
    raise exception 'Chỉ có thể xác nhận hoàn thành booking đã được xác nhận.';
  end if;

  if not exists (
    select 1 from public.journey_photos
    where booking_id = v_booking.id
      and user_id = auth.uid()
  ) then
    raise exception 'Bạn hãy tải lên ít nhất một ảnh kỷ niệm trước khi xác nhận hoàn thành.';
  end if;

  update public.bookings
  set status = 'completed'
  where id = v_booking.id;

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

revoke all on function public.customer_complete_journey(uuid) from public;
grant execute on function public.customer_complete_journey(uuid) to authenticated;
