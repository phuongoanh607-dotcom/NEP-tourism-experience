-- NÉP: support the full bank list in demo payment records.
-- Apply this migration in Supabase SQL Editor after previous migrations.

alter table public.payment_transactions
  drop constraint if exists payment_transactions_provider_check;

alter table public.payment_transactions
  add constraint payment_transactions_provider_check
  check (provider in (
    'VCB','TCB','MB','ACB','BIDV','CTG','AGR','VPB','TPB','STB',
    'HDB','VIB','SHB','MSB','OCB','EIB','LPB','SEAB','BAB','PVC'
  ));

create or replace function public.confirm_demo_payment(p_booking_id uuid, p_provider text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_amount numeric(14,2);
  v_reference text;
  v_existing public.payment_transactions%rowtype;
begin
  if auth.uid() is null then raise exception 'Vui lòng đăng nhập để tiếp tục.'; end if;
  if p_provider not in (
    'VCB','TCB','MB','ACB','BIDV','CTG','AGR','VPB','TPB','STB',
    'HDB','VIB','SHB','MSB','OCB','EIB','LPB','SEAB','BAB','PVC'
  ) then raise exception 'Ngân hàng mô phỏng không hợp lệ.'; end if;

  select * into v_booking from public.bookings
    where id = p_booking_id and user_id = auth.uid() for update;
  if not found then raise exception 'Không tìm thấy booking của tài khoản này.'; end if;

  select * into v_existing from public.payment_transactions where booking_id = p_booking_id;
  if found then
    return jsonb_build_object('success',true,'already_paid',true,
      'reference_code',v_existing.reference_code,'provider',v_existing.provider,
      'amount',v_existing.amount,'status',v_existing.status);
  end if;

  v_amount := v_booking.quoted_total;
  if v_amount is null or v_amount <= 0 then
    raise exception 'Booking chưa có tổng chi phí hợp lệ nên chưa thể thanh toán mô phỏng.';
  end if;
  if v_booking.status = 'cancelled' then raise exception 'Booking đã bị hủy.'; end if;

  v_reference := 'NEP-DEMO-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
  insert into public.payment_transactions(booking_id,user_id,provider,amount,reference_code,status)
  values(p_booking_id,auth.uid(),p_provider,v_amount,v_reference,'paid_demo');

  update public.bookings set payment_status='paid_demo', paid_at=now(),
    payment_method=p_provider, payment_reference=v_reference
  where id=p_booking_id;

  return jsonb_build_object('success',true,'already_paid',false,
    'reference_code',v_reference,'provider',p_provider,'amount',v_amount,'status','paid_demo');
end;
$$;
revoke all on function public.confirm_demo_payment(uuid,text) from public;
grant execute on function public.confirm_demo_payment(uuid,text) to authenticated;
