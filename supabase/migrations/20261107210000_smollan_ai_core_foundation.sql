-- SMOLLAN AI Core foundation.
-- Additive only: this migration does not alter existing operational tables or policies.

create table if not exists public.smollan_ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  department text not null default 'operations',
  project_id uuid references public.smollan_projects(id) on delete set null,
  title text not null default 'New AI conversation',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.smollan_ai_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user','assistant','tool')),
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.smollan_ai_runs (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.smollan_ai_conversations(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  department text not null default 'operations',
  trigger_type text not null default 'chat' check (trigger_type in ('chat','event','scheduled','manual_analysis')),
  status text not null default 'running' check (status in ('running','completed','failed','cancelled')),
  model_provider text,
  model_name text,
  input_tokens integer not null default 0 check (input_tokens >= 0),
  output_tokens integer not null default 0 check (output_tokens >= 0),
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.smollan_ai_memory (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('company','department','project','user')),
  department text,
  project_id uuid references public.smollan_projects(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  source_type text not null default 'curated',
  source_id text,
  is_approved boolean not null default false,
  confidence numeric(4,3) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  search_vector tsvector generated always as (
    to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,''))
  ) stored,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint smollan_ai_memory_scope_fields_check check (
    (scope_type <> 'department' or department is not null) and
    (scope_type <> 'project' or project_id is not null) and
    (scope_type <> 'user' or user_id is not null)
  )
);

create table if not exists public.smollan_ai_recommendations (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.smollan_ai_conversations(id) on delete set null,
  run_id uuid references public.smollan_ai_runs(id) on delete set null,
  project_id uuid references public.smollan_projects(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete cascade,
  department text not null default 'operations',
  title text not null,
  rationale text not null,
  action_type text not null,
  proposed_payload jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft','pending_approval','approved','rejected','executed','expired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_ai_audit_logs (
  id bigint generated always as identity primary key,
  run_id uuid references public.smollan_ai_runs(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists smollan_ai_conversations_user_updated_idx
  on public.smollan_ai_conversations(user_id, updated_at desc);
create index if not exists smollan_ai_messages_conversation_created_idx
  on public.smollan_ai_messages(conversation_id, created_at);
create index if not exists smollan_ai_runs_user_created_idx
  on public.smollan_ai_runs(user_id, created_at desc);
create index if not exists smollan_ai_memory_search_idx
  on public.smollan_ai_memory using gin(search_vector);
create index if not exists smollan_ai_memory_scope_idx
  on public.smollan_ai_memory(scope_type, department, project_id)
  where is_approved = true;
create index if not exists smollan_ai_recommendations_user_created_idx
  on public.smollan_ai_recommendations(created_by, created_at desc);
create index if not exists smollan_ai_recommendations_project_status_idx
  on public.smollan_ai_recommendations(project_id, status);
create index if not exists smollan_ai_audit_user_created_idx
  on public.smollan_ai_audit_logs(user_id, created_at desc);

alter table public.smollan_ai_conversations enable row level security;
alter table public.smollan_ai_messages enable row level security;
alter table public.smollan_ai_runs enable row level security;
alter table public.smollan_ai_memory enable row level security;
alter table public.smollan_ai_recommendations enable row level security;
alter table public.smollan_ai_audit_logs enable row level security;

revoke all on public.smollan_ai_conversations, public.smollan_ai_messages,
  public.smollan_ai_runs, public.smollan_ai_memory,
  public.smollan_ai_recommendations, public.smollan_ai_audit_logs
  from anon, authenticated;

grant select, insert, update, delete on public.smollan_ai_conversations to authenticated;
grant select, insert on public.smollan_ai_messages to authenticated;
grant select, insert, update on public.smollan_ai_runs to authenticated;
grant select on public.smollan_ai_memory to authenticated;
grant select, insert on public.smollan_ai_recommendations to authenticated;
grant select, insert on public.smollan_ai_audit_logs to authenticated;
grant usage, select on sequence public.smollan_ai_audit_logs_id_seq to authenticated;

create policy "ai users manage own conversations"
  on public.smollan_ai_conversations for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid()) and
    (project_id is null or exists (
      select 1 from public.smollan_projects p where p.id = project_id
    ))
  );

create policy "ai users read own messages"
  on public.smollan_ai_messages for select to authenticated
  using (exists (
    select 1 from public.smollan_ai_conversations c
    where c.id = conversation_id and c.user_id = (select auth.uid())
  ));

create policy "ai users append own conversation messages"
  on public.smollan_ai_messages for insert to authenticated
  with check (
    user_id = (select auth.uid()) and exists (
      select 1 from public.smollan_ai_conversations c
      where c.id = conversation_id and c.user_id = (select auth.uid())
    )
  );

create policy "ai users read own runs"
  on public.smollan_ai_runs for select to authenticated
  using (user_id = (select auth.uid()));

create policy "ai users create own runs"
  on public.smollan_ai_runs for insert to authenticated
  with check (
    user_id = (select auth.uid()) and exists (
      select 1 from public.smollan_ai_conversations c
      where c.id = conversation_id and c.user_id = (select auth.uid())
    )
  );

create policy "ai users update own runs"
  on public.smollan_ai_runs for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "ai users read authorized approved memory"
  on public.smollan_ai_memory for select to authenticated
  using (
    is_approved = true and exists (
      select 1 from public.smollan_memberships m
      where m.user_id = (select auth.uid()) and m.is_active and (
        scope_type = 'company'
        or (scope_type = 'user' and smollan_ai_memory.user_id = (select auth.uid()))
        or (scope_type = 'project' and exists (
          select 1 from public.smollan_projects p where p.id = project_id
        ))
        or (scope_type = 'department' and (
          (department = 'operations' and m.role::text in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager')) or
          (department = 'finance' and m.role::text in ('platform_admin','leadership','finance')) or
          (department = 'hr' and m.role::text in ('platform_admin','leadership','hr_coordinator')) or
          (department = 'cluster' and m.role::text in ('platform_admin','leadership','field_manager','supervisor')) or
          (department = 'management' and m.role::text in ('platform_admin','leadership')) or
          (department = 'procurement' and m.role::text in ('platform_admin','leadership','procurement_production'))
        ))
      )
    )
  );

create policy "ai users read own recommendations"
  on public.smollan_ai_recommendations for select to authenticated
  using (created_by = (select auth.uid()));

create policy "ai users create own recommendations"
  on public.smollan_ai_recommendations for insert to authenticated
  with check (
    created_by = (select auth.uid()) and
    status = 'draft' and
    (project_id is null or exists (
      select 1 from public.smollan_projects p where p.id = project_id
    ))
  );

create policy "ai users read own audit entries"
  on public.smollan_ai_audit_logs for select to authenticated
  using (
    user_id = (select auth.uid()) or exists (
      select 1 from public.smollan_memberships m
      where m.user_id = (select auth.uid()) and m.is_active
        and m.role::text in ('platform_admin','leadership')
    )
  );

create policy "ai users append own audit entries"
  on public.smollan_ai_audit_logs for insert to authenticated
  with check (
    user_id = (select auth.uid()) and
    (run_id is null or exists (
      select 1 from public.smollan_ai_runs r
      where r.id = run_id and r.user_id = (select auth.uid())
    ))
  );

comment on table public.smollan_ai_memory is
  'Approved, scoped business knowledge. Never store secrets, government IDs, bank details or raw sensitive HR records here.';
comment on table public.smollan_ai_recommendations is
  'AI-generated proposals only. This table does not execute operational changes; approvals and execution are separate workflows.';
