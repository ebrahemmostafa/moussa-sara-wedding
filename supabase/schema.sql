-- Run once in Supabase: SQL Editor → New query → paste → Run.

create table if not exists public.rsvps (
  id                   uuid primary key default gen_random_uuid(),
  created_at           timestamptz not null default now(),
  full_name            text not null check (char_length(full_name) between 1 and 500),
  email                text check (char_length(email) <= 200),
  attendance           text not null check (attendance in ('yes', 'no')),
  guest_count          int  not null default 1 check (guest_count between 1 and 20),
  adult_count          int  not null default 1 check (adult_count between 0 and 20),
  children_count       int  not null default 0 check (children_count between 0 and 20),
  dietary_requirements text check (char_length(dietary_requirements) <= 2000),
  message              text check (char_length(message) <= 2000)
);

alter table public.rsvps enable row level security;

-- Guests (not signed in) can only add an RSVP. They cannot read, edit or delete.
drop policy if exists "guests can submit" on public.rsvps;
create policy "guests can submit" on public.rsvps
  for insert to anon with check (true);

-- Only accounts listed in rsvp_admins can read. Being signed in is not enough,
-- because Supabase allows public sign-ups unless you turn them off.
create table if not exists public.rsvp_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table public.rsvp_admins enable row level security;
revoke all on public.rsvp_admins from anon, authenticated;

drop policy if exists "admins can read" on public.rsvps;
create policy "admins can read" on public.rsvps
  for select to authenticated
  using (exists (select 1 from public.rsvp_admins a where a.user_id = auth.uid()));

-- Guests may only fill in the form fields; id and created_at are always set by the database.
revoke insert on public.rsvps from anon;
grant insert (full_name, email, attendance, guest_count, adult_count, children_count, dietary_requirements, message)
  on public.rsvps to anon;
grant select on public.rsvps to authenticated;

-- Live updates on rsvps.html
do $$ begin
  alter publication supabase_realtime add table public.rsvps;
exception when duplicate_object then null; end $$;

-- After creating your admin user(s) in Authentication → Users, add each one:
--   insert into public.rsvp_admins (user_id)
--   select id from auth.users where email = 'you@example.com';
--
-- Also recommended: Authentication → Sign In / Providers → Email →
-- turn OFF "Allow new users to sign up".
