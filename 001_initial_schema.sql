-- NÉP initial schema. Run in Supabase SQL Editor as project owner.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(), name text not null, region text not null,
  category text not null, description text not null, lat double precision not null,
  lng double precision not null, price_from integer not null default 0 check(price_from >= 0),
  duration text, season text, is_published boolean not null default false,
  qr_token uuid not null default gen_random_uuid() unique,
  created_at timestamptz not null default now()
);
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(), booking_code text unique not null default ('NEP-' || upper(substr(encode(gen_random_bytes(6),'hex'),1,10))),
  user_id uuid not null references public.profiles(id) on delete cascade,
  place_name text not null, travel_date date not null, guests integer not null check(guests between 1 and 30),
  note text, status text not null default 'pending' check(status in ('pending','confirmed','completed','cancelled')),
  created_at timestamptz not null default now()
);
create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  place_id uuid not null references public.places(id) on delete cascade,
  checked_in_at timestamptz not null default now(), unique(user_id,place_id)
);
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check(char_length(content) between 1 and 2000), created_at timestamptz not null default now()
);
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check(rating between 1 and 5), comment text not null,
  would_recommend boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  issue text not null, detail text not null, contact text not null,
  status text not null default 'open' check(status in ('open','in_progress','resolved')),
  created_at timestamptz not null default now()
);
create table if not exists public.storytellers (
  id uuid primary key default gen_random_uuid(), name text not null, bio text not null,
  region text not null, specialty text not null, contact text,
  is_published boolean not null default false, created_at timestamptz not null default now()
);

-- Public catalogue deliberately excludes private QR tokens and contact details.
create or replace view public.published_places as
select id,name,region,category,description,lat,lng,price_from,duration,season,created_at
from public.places where is_published = true;
create or replace view public.published_storytellers as
select id,name,bio,region,specialty,created_at from public.storytellers where is_published = true;
grant select on public.published_places, public.published_storytellers to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.places enable row level security;
alter table public.bookings enable row level security;
alter table public.checkins enable row level security;
alter table public.memories enable row level security;
alter table public.feedback enable row level security;
alter table public.support_tickets enable row level security;
alter table public.storytellers enable row level security;

create policy "profile read own or admin" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profile update own basic fields" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = 'customer');
create policy "admin manage places" on public.places for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "customer read own bookings" on public.bookings for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "customer create own bookings" on public.bookings for insert to authenticated with check (user_id = auth.uid());
create policy "admin update bookings" on public.bookings for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "read own checkins" on public.checkins for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "read own memories" on public.memories for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "create own memories" on public.memories for insert to authenticated with check (user_id = auth.uid());
create policy "delete own memories" on public.memories for delete to authenticated using (user_id = auth.uid());
create policy "read own feedback or admin" on public.feedback for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "create own feedback" on public.feedback for insert to authenticated with check (user_id = auth.uid());
create policy "admin manage feedback" on public.feedback for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "read own support or admin" on public.support_tickets for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "create own support" on public.support_tickets for insert to authenticated with check (user_id = auth.uid());
create policy "admin manage support" on public.support_tickets for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin manage storytellers" on public.storytellers for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Redeem a QR only for the signed-in user. Tokens are never exposed in the public catalogue view.
create or replace function public.redeem_place_qr(p_token uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_place public.places%rowtype; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Vui lòng đăng nhập để check-in.'; end if;
  select * into v_place from public.places where qr_token = p_token and is_published = true;
  if not found then raise exception 'Mã QR không hợp lệ hoặc điểm đến chưa được công khai.'; end if;
  insert into public.checkins(user_id, place_id) values(auth.uid(),v_place.id)
  on conflict(user_id,place_id) do nothing returning id into v_id;
  if v_id is null then return jsonb_build_object('message','Bạn đã check-in điểm này trước đó.','place_name',v_place.name,'already_checked_in',true); end if;
  return jsonb_build_object('message','Check-in thành công! Bạn đã mở khóa một dấu mốc khám phá.','place_name',v_place.name,'already_checked_in',false);
end; $$;
grant execute on function public.redeem_place_qr(uuid) to authenticated;

create or replace function public.admin_get_place_qr_token(p_place_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_token uuid;
begin
  if not public.is_admin() then raise exception 'Bạn không có quyền quản trị.'; end if;
  select qr_token into v_token from public.places where id=p_place_id and is_published=true;
  if v_token is null then raise exception 'Không tìm thấy QR của điểm đến.'; end if;
  return v_token;
end; $$;
grant execute on function public.admin_get_place_qr_token(uuid) to authenticated;

-- IMPORTANT: after creating the first account, promote that account using the SQL below.
-- update public.profiles set role='admin' where id=(select id from auth.users where email='YOUR_ADMIN_EMAIL');

create table if not exists public.storyteller_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  storyteller_id uuid not null references public.storytellers(id) on delete cascade,
  preferred_date date,
  note text,
  status text not null default 'pending' check(status in ('pending','contacted','confirmed','cancelled')),
  created_at timestamptz not null default now()
);
alter table public.storyteller_requests enable row level security;
create policy "read own storyteller requests or admin" on public.storyteller_requests for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "create own storyteller request" on public.storyteller_requests for insert to authenticated with check (user_id = auth.uid());
create policy "admin manage storyteller requests" on public.storyteller_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());

create or replace view public.my_checkins as
select c.id,c.user_id,c.place_id,p.name as place_name,c.checked_in_at
from public.checkins c join public.places p on p.id=c.place_id
where c.user_id=auth.uid();
grant select on public.my_checkins to authenticated;

-- API privileges: RLS policies above remain the authorization boundary.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profiles, public.places, public.bookings,
  public.checkins, public.memories, public.feedback, public.support_tickets,
  public.storytellers, public.storyteller_requests to authenticated;
grant select on public.published_places, public.published_storytellers to anon, authenticated;
grant select on public.my_checkins to authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
