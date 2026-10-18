-- Run once in Supabase: SQL Editor → New query → paste → Run.
-- Replace YOUR-PASSCODE below with the passcode for rsvps.html before running.
-- (This repo is public, so the real passcode is not stored here.)

create table if not exists public."moussa-sara-rsvp" (
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

alter table public."moussa-sara-rsvp" enable row level security;

-- Guests can only add an RSVP: no reading, editing or deleting.
revoke all on public."moussa-sara-rsvp" from anon, authenticated;
drop policy if exists "guests can submit" on public."moussa-sara-rsvp";
create policy "guests can submit" on public."moussa-sara-rsvp"
  for insert to anon with check (true);
-- Only the form fields; id and created_at are always set by the database.
grant insert (full_name, email, attendance, guest_count, adult_count, children_count, dietary_requirements, message)
  on public."moussa-sara-rsvp" to anon;

-- Wrong passcode attempts, used to lock the page after too many guesses.
create table if not exists public."moussa-sara-rsvp-attempts" (
  at timestamptz not null default now()
);
alter table public."moussa-sara-rsvp-attempts" enable row level security;
revoke all on public."moussa-sara-rsvp-attempts" from anon, authenticated;

-- rsvps.html reads the list through this function, which checks the passcode
-- on the server. After 20 wrong guesses in 10 minutes it refuses everyone
-- (even the right passcode) until the window passes.
drop function if exists public.get_moussa_sara_rsvp(text);
create or replace function public.get_moussa_sara_rsvp(passcode text)
returns json
language plpgsql
security definer
set search_path = public
as $$
begin
  -- One check at a time, so parallel guesses can't slip past the counter.
  perform pg_advisory_xact_lock(20261120);
  delete from public."moussa-sara-rsvp-attempts" where at < now() - interval '1 day';
  if (select count(*) from public."moussa-sara-rsvp-attempts" where at > now() - interval '10 minutes') >= 20 then
    return json_build_object('ok', false, 'error', 'locked');
  end if;
  if passcode is distinct from 'YOUR-PASSCODE' then
    insert into public."moussa-sara-rsvp-attempts" default values;
    perform pg_sleep(2);
    return json_build_object('ok', false, 'error', 'wrong');
  end if;
  return json_build_object('ok', true, 'rows', coalesce(
    (select json_agg(r order by r.created_at desc) from public."moussa-sara-rsvp" r), '[]'::json));
end;
$$;

revoke all on function public.get_moussa_sara_rsvp(text) from public;
grant execute on function public.get_moussa_sara_rsvp(text) to anon;
