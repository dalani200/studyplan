-- Run this once in Supabase Dashboard > SQL Editor.
create table if not exists public.study_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  study_date date not null default current_date,
  subject text not null default '',
  content text not null check (char_length(content) <= 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists study_logs_user_date_idx
  on public.study_logs (user_id, study_date desc, created_at desc);

alter table public.study_logs enable row level security;
revoke all on table public.study_logs from anon, authenticated;
grant select, insert, update, delete on table public.study_logs to authenticated;

drop policy if exists "Read own study logs" on public.study_logs;
create policy "Read own study logs"
  on public.study_logs for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Create own study logs" on public.study_logs;
create policy "Create own study logs"
  on public.study_logs for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Update own study logs" on public.study_logs;
create policy "Update own study logs"
  on public.study_logs for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Delete own study logs" on public.study_logs;
create policy "Delete own study logs"
  on public.study_logs for delete to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.set_study_log_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists study_logs_updated_at on public.study_logs;
create trigger study_logs_updated_at
  before update on public.study_logs
  for each row execute function public.set_study_log_updated_at();
