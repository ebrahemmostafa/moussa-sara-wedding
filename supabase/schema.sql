-- Run once in Supabase: SQL Editor → New query → paste → Run.
-- Replace YOUR-PASSCODE below with the passcode for rsvps.html before running.
-- (This repo is public, so the real passcode is not stored here.)

create table if not exists public.wedding_rsvps (
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

alter table public.wedding_rsvps enable row level security;

-- Guests can only add an RSVP: no reading, editing or deleting.
revoke all on public.wedding_rsvps from anon, authenticated;
drop policy if exists "guests can submit" on public.wedding_rsvps;
create policy "guests can submit" on public.wedding_rsvps
  for insert to anon with check (true);
-- Only the form fields; id and created_at are always set by the database.
grant insert (full_name, email, attendance, guest_count, adult_count, children_count, dietary_requirements, message)
  on public.wedding_rsvps to anon;

-- rsvps.html reads the list through this function, which checks the passcode
-- on the server. A wrong passcode waits 2 seconds to slow down guessing.
create or replace function public.get_wedding_rsvps(passcode text)
returns setof public.wedding_rsvps
language plpgsql
security definer
set search_path = public
as $$
begin
  if passcode is distinct from 'YOUR-PASSCODE' then
    perform pg_sleep(2);
    raise exception 'Wrong passcode' using errcode = '28P01';
  end if;
  return query select * from public.wedding_rsvps order by created_at desc;
end;
$$;

revoke all on function public.get_wedding_rsvps(text) from public;
grant execute on function public.get_wedding_rsvps(text) to anon;
