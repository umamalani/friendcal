-- ============================================================
-- FriendCal Database Schema
-- Run this in Supabase Dashboard > SQL Editor
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

-- ============================================================
-- Row Level Security (RLS) — keeps data private
-- ============================================================

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.invites enable row level security;

-- Profiles: users can read all profiles, only edit their own
create policy "Profiles are viewable by everyone" on public.profiles
  for select using (true);

create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id);

-- Events: viewable if you created it or are invited
create policy "Creator can manage their events" on public.events
  for all using (auth.uid() = created_by);

create policy "Invited users can view events" on public.events
  for select using (
    exists (
      select 1 from public.invites
      where invites.event_id = events.id
      and invites.user_id = auth.uid()
    )
  );

-- Invites: users can see their own invites, event creators can manage invites
create policy "Users can view their own invites" on public.invites
  for select using (auth.uid() = user_id);

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
