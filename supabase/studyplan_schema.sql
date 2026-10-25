-- Study operating plan schema. Run once in Supabase SQL Editor.
-- Keeps the existing public.study_logs table and its data untouched.

create table if not exists public.study_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  trial_started_on date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_date date not null,
  category text not null check (category in ('mentoring','company','macro_portfolio','recall','inbox','optional','break')),
  title text not null check (char_length(title) between 1 and 180),
  planned_minutes integer not null check (planned_minutes between 5 and 1440),
  actual_minutes integer not null default 0 check (actual_minutes between 0 and 1440),
  start_time time,
  status text not null default 'planned' check (status in ('planned','done','partial','skipped')),
  actual_result text not null default '',
  next_step text not null default '',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.study_companies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  status text not null default 'candidate' check (status in ('candidate','active','paused','done')),
  is_primary boolean not null default false,
  reason text not null default '',
  change_to_check text not null default '',
  core_question text not null default '',
  verification_materials text not null default '',
  started_on date,
  project_week smallint not null default 1 check (project_week between 1 and 4),
  next_action text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists study_companies_one_focus_idx
  on public.study_companies(user_id) where is_primary and status = 'active';

create table if not exists public.study_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  record_type text not null check (record_type in ('weekly_plan','mentoring','weekly_review','company_research','dcf_review','judgment_review','trial_review')),
  record_date date not null default current_date,
  week_start date,
  title text not null check (char_length(title) between 1 and 180),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.study_questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  area text not null check (area in ('mentoring','company','macro')),
  question text not null check (char_length(question) between 1 and 700),
  due_on date not null default current_date,
  review_stage smallint not null default 0 check (review_stage between 0 and 3),
  last_answer text not null default '',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.study_inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  saved_on date not null default current_date,
  title text not null check (char_length(title) between 1 and 240),
  source text not null default '',
  source_url text not null default '',
  linked_question text not null default '',
  reason text not null default '',
  next_action text not null default 'read' check (next_action in ('read','check','link','archive','discard')),
  queue text not null default 'this_week' check (queue in ('now','this_week','reference','skip')),
  processed boolean not null default false,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists study_sessions_user_date_idx on public.study_sessions(user_id, session_date, start_time);
create index if not exists study_records_user_type_date_idx on public.study_records(user_id, record_type, record_date desc);
create index if not exists study_questions_user_due_idx on public.study_questions(user_id, due_on) where completed_at is null;
create index if not exists study_inbox_user_queue_idx on public.study_inbox(user_id, processed, queue, saved_on desc);

do $$
declare t text;
begin
  foreach t in array array['study_settings','study_sessions','study_companies','study_records','study_questions','study_inbox'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon', t);
    execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    execute format('drop policy if exists "users own %s" on public.%I', t, t);
    execute format('create policy "users own %s" on public.%I for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)', t, t);
  end loop;
end $$;

create or replace function public.studyplan_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['study_settings','study_sessions','study_companies','study_records','study_questions','study_inbox'] loop
    execute format('drop trigger if exists studyplan_updated_at on public.%I', t);
    execute format('create trigger studyplan_updated_at before update on public.%I for each row execute function public.studyplan_touch_updated_at()', t);
  end loop;
end $$;
