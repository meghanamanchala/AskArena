create extension if not exists "pgcrypto";

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  host_name text not null,
  status text not null check (status in ('waiting', 'live', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  content text not null,
  author_name text not null,
  votes int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  voter_name text not null,
  created_at timestamptz not null default now(),
  unique (question_id, voter_name)
);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'events'
  ) then
    alter publication supabase_realtime add table public.events;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'questions'
  ) then
    alter publication supabase_realtime add table public.questions;
  end if;
end $$;

grant usage on schema public to anon, authenticated;

grant select, insert on table public.events to anon, authenticated;
grant update (status) on table public.events to anon, authenticated;

grant select, insert on table public.questions to anon, authenticated;

grant select, insert on table public.votes to anon, authenticated;

alter table public.events enable row level security;
alter table public.questions enable row level security;
alter table public.votes enable row level security;

drop policy if exists "Public can read events" on public.events;
create policy "Public can read events"
on public.events
for select
using (true);

drop policy if exists "Public can create events" on public.events;
create policy "Public can create events"
on public.events
for insert
with check (
  char_length(title) > 0
  and char_length(host_name) > 0
  and char_length(code) = 6
  and status in ('waiting', 'live', 'closed')
);

drop policy if exists "Public can update event status" on public.events;
create policy "Public can update event status"
on public.events
for update
using (true)
with check (status in ('waiting', 'live', 'closed'));

drop policy if exists "Public can read questions" on public.questions;
create policy "Public can read questions"
on public.questions
for select
using (true);

drop policy if exists "Public can create questions" on public.questions;
create policy "Public can create questions"
on public.questions
for insert
with check (
  char_length(content) > 0
  and char_length(author_name) > 0
  and exists (
    select 1
    from public.events e
    where e.id = event_id
  )
);

drop policy if exists "Public can update question votes" on public.questions;

drop policy if exists "Public can read votes" on public.votes;
create policy "Public can read votes"
on public.votes
for select
using (true);

drop policy if exists "Public can create votes" on public.votes;
create policy "Public can create votes"
on public.votes
for insert
with check (
  char_length(voter_name) > 0
  and exists (
    select 1
    from public.questions q
    where q.id = question_id
  )
);

create or replace function public.cast_vote(p_question_id uuid, p_voter_name text)
returns boolean
language plpgsql
security invoker
set search_path = public
as $$
declare
  updated_rows int;
begin
  if char_length(trim(p_voter_name)) = 0 then
    raise exception 'Voter name is required';
  end if;

  with inserted as (
    insert into public.votes (question_id, voter_name)
    values (p_question_id, trim(p_voter_name))
    on conflict (question_id, voter_name) do nothing
    returning 1
  )
  update public.questions q
  set votes = q.votes + 1
  where q.id = p_question_id
    and exists (select 1 from inserted);

  get diagnostics updated_rows = row_count;
  return updated_rows > 0;
end;
$$;

grant execute on function public.cast_vote(uuid, text) to anon, authenticated;
