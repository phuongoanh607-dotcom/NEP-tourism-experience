-- NÉP QR Storytelling: public destination stories with admin-managed QR links
create extension if not exists pgcrypto;
create table if not exists public.destination_stories (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique,
 title text not null,
 region text not null,
 category text not null default 'Câu chuyện địa phương',
 excerpt text not null,
 story_body text not null,
 highlight text,
 visit_tips text,
 lat double precision,
 lng double precision,
 cover_image_url text,
 audio_url text,
 is_published boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists destination_stories_published_idx on public.destination_stories(is_published, created_at desc);
alter table public.destination_stories enable row level security;
drop policy if exists "Published destination stories are readable by everyone" on public.destination_stories;
create policy "Published destination stories are readable by everyone"
 on public.destination_stories for select to anon, authenticated using (is_published = true);
drop policy if exists "Admins manage destination stories" on public.destination_stories;
create policy "Admins manage destination stories"
 on public.destination_stories for all to authenticated
 using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
 with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
