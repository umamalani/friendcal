-- ============================================================
-- FriendCal Database Schema
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================


-- ============================================================
-- Core tables
-- ============================================================

-- Profiles table (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Auto-create a profile when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Events table
create table public.events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz,
  location text,
  created_by uuid references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now()
);

-- Invites table (who is invited to which event, and their RSVP)
create table public.invites (
  id uuid default gen_random_uuid() primary key,
  event_id uuid references public.events(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  status text default 'pending' check (status in ('pending', 'accepted', 'declined')),
  invited_at timestamptz default now(),
  unique (event_id, user_id)
);

-- Where each user will be during a date range
create table public.locations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  city text not null,
  country text,
  start_date date not null,
  end_date date,
  label text, -- e.g. "internship", "home", "vacation"
  created_at timestamptz default now()
);

-- Internship details
create table public.internships (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  company text not null,
  city text not null,
  country text,
  start_date date not null,
  end_date date not null,
  created_at timestamptz default now()
);

-- General availability blocks (free/busy date ranges)
create table public.availability (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  start_date date not null,
  end_date date not null,
  status text default 'free' check (status in ('free', 'busy')),
  note text,
  created_at timestamptz default now()
);


-- ============================================================
-- Row Level Security (RLS)
-- Read = any authenticated user
-- Write = only your own data
-- Note: disable public signups in Supabase Auth settings so
-- only invited friends can create accounts.
-- ============================================================

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.invites enable row level security;
alter table public.locations enable row level security;
alter table public.internships enable row level security;
alter table public.availability enable row level security;


-- Profiles
create policy "Authenticated users read profiles" on public.profiles
  for select using (auth.role() = 'authenticated');

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);


-- Events
create policy "Authenticated users read events" on public.events
  for select using (auth.role() = 'authenticated');

create policy "Creator can manage their events" on public.events
  for all using (auth.uid() = created_by);


-- Invites
create policy "Authenticated users read invites" on public.invites
  for select using (auth.role() = 'authenticated');

create policy "Event creator can manage invites" on public.invites
  for all using (
    exists (
      select 1 from public.events
      where events.id = invites.event_id
      and events.created_by = auth.uid()
    )
  );

create policy "Invited users can update their RSVP" on public.invites
  for update using (auth.uid() = user_id);


-- Locations
create policy "Authenticated users read locations" on public.locations
  for select using (auth.role() = 'authenticated');

create policy "Users manage own locations" on public.locations
  for all using (auth.uid() = user_id);


-- Internships
create policy "Authenticated users read internships" on public.internships
  for select using (auth.role() = 'authenticated');

create policy "Users manage own internships" on public.internships
  for all using (auth.uid() = user_id);


-- Availability
create policy "Authenticated users read availability" on public.availability
  for select using (auth.role() = 'authenticated');

create policy "Users manage own availability" on public.availability
  for all using (auth.uid() = user_id);