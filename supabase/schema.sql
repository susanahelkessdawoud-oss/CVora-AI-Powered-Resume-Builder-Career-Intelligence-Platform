-- CVora database schema
-- Run this once in your Supabase project's SQL editor:
-- https://supabase.com/dashboard/project/bobayuhrningbnsrwvkg/sql/new

create extension if not exists pgcrypto;

create table if not exists public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  document_type text not null default 'resume' check (document_type in ('cv', 'resume')),
  full_name text not null default '',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists resumes_user_id_idx on public.resumes (user_id);

-- Keep updated_at current on every write
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists resumes_set_updated_at on public.resumes;
create trigger resumes_set_updated_at
  before update on public.resumes
  for each row
  execute function public.set_updated_at();

-- Row Level Security: each user can only see and manage their own resumes
alter table public.resumes enable row level security;

drop policy if exists "Users can view their own resumes" on public.resumes;
create policy "Users can view their own resumes"
  on public.resumes for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own resumes" on public.resumes;
create policy "Users can insert their own resumes"
  on public.resumes for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own resumes" on public.resumes;
create policy "Users can update their own resumes"
  on public.resumes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own resumes" on public.resumes;
create policy "Users can delete their own resumes"
  on public.resumes for delete
  using (auth.uid() = user_id);

-- Achievement Vault: a personal, reusable pool of achievements the user
-- can draw from when building any CV/Resume.
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text not null default '',
  date text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists achievements_user_id_idx on public.achievements (user_id);

alter table public.achievements enable row level security;

drop policy if exists "Users can view their own achievements" on public.achievements;
create policy "Users can view their own achievements"
  on public.achievements for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own achievements" on public.achievements;
create policy "Users can insert their own achievements"
  on public.achievements for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own achievements" on public.achievements;
create policy "Users can update their own achievements"
  on public.achievements for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own achievements" on public.achievements;
create policy "Users can delete their own achievements"
  on public.achievements for delete
  using (auth.uid() = user_id);
