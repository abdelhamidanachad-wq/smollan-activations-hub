-- Project operations: calendar, task kanban, deliverable lifecycle and per-store daily goodies quotas.
create table if not exists public.smollan_project_working_days (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  store_id uuid references public.smollan_stores(id) on delete cascade,
  work_date date not null,
  is_activation_day boolean not null default true,
  planned_promoters integer not null default 0 check (planned_promoters >= 0),
  notes text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(project_id, store_id, work_date)
);
create index if not exists smollan_project_working_days_date_idx on public.smollan_project_working_days(work_date, project_id);

create table if not exists public.smollan_project_tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 180),
  description text not null default '',
  status text not null default 'backlog' check(status in ('backlog','todo','in_progress','blocked','review','done','cancelled')),
  priority text not null default 'medium' check(priority in ('low','medium','high','urgent')),
  task_type text not null default 'general' check(task_type in ('planning','store_activation','recruitment','posm','goodies','uniforms','attendance','reporting','procurement','finance','general')),
  owner_user_id uuid references auth.users(id),
  owner_promoter_id uuid references public.smollan_promoters(id) on delete set null,
  store_id uuid references public.smollan_stores(id) on delete set null,
  start_date date,
  due_date date,
  completed_at timestamptz,
  sort_order integer not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (due_date is null or start_date is null or due_date >= start_date)
);
create index if not exists smollan_project_tasks_board_idx on public.smollan_project_tasks(project_id, status, sort_order, due_date);

create table if not exists public.smollan_project_deliverables (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  deliverable_type text not null check(deliverable_type in ('posm','goodie')),
  plv_material_id uuid references public.smollan_plv_materials(id) on delete set null,
  gift_id uuid references public.smollan_gifts(id) on delete set null,
  name text not null check(char_length(trim(name)) between 1 and 180),
  quantity integer not null default 0 check(quantity >= 0),
  design_status text not null default 'not_started' check(design_status in ('not_started','in_progress','submitted','client_review','changes_requested','validated','not_applicable')),
  design_validated_at timestamptz,
  design_validated_by uuid references auth.users(id),
  production_status text not null default 'not_started' check(production_status in ('not_started','quoted','approved','in_production','quality_check','completed','on_hold','not_applicable')),
  production_start_date date,
  production_due_date date,
  production_completed_at timestamptz,
  dispatch_status text not null default 'not_ready' check(dispatch_status in ('not_ready','ready','partially_dispatched','dispatched','delivered','not_applicable')),
  dispatched_at timestamptz,
  dispatch_reference text,
  installation_status text not null default 'not_applicable' check(installation_status in ('not_applicable','pending','scheduled','in_progress','installed','failed','verified')),
  installation_due_date date,
  installed_at timestamptz,
  installation_evidence_url text,
  return_dispatch_status text not null default 'not_applicable' check(return_dispatch_status in ('not_applicable','pending','scheduled','collected','in_transit','received','reconciled','missing_items')),
  return_due_date date,
  returned_at timestamptz,
  returned_quantity integer not null default 0 check(returned_quantity >= 0),
  notes text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((deliverable_type='posm' and (plv_material_id is not null or gift_id is null)) or (deliverable_type='goodie' and (gift_id is not null or plv_material_id is null))),
  check(returned_quantity <= quantity)
);
create index if not exists smollan_project_deliverables_project_idx on public.smollan_project_deliverables(project_id, deliverable_type, created_at desc);

create table if not exists public.smollan_goodie_store_day_quotas (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  store_id uuid not null references public.smollan_stores(id) on delete cascade,
  gift_id uuid not null references public.smollan_gifts(id) on delete cascade,
  activation_date date not null,
  quota_quantity integer not null check(quota_quantity >= 0),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(project_id, store_id, gift_id, activation_date),
  foreign key(project_id, store_id, activation_date) references public.smollan_project_working_days(project_id, store_id, work_date) deferrable initially deferred
);
create index if not exists smollan_goodie_store_day_quotas_lookup_idx on public.smollan_goodie_store_day_quotas(project_id, activation_date, store_id);

create table if not exists public.smollan_goodie_distributions (
  id uuid primary key default gen_random_uuid(),
  quota_id uuid not null references public.smollan_goodie_store_day_quotas(id) on delete cascade,
  distributed_quantity integer not null check(distributed_quantity > 0),
  distribution_time timestamptz not null default now(),
  distributed_by uuid references auth.users(id),
  promoter_id uuid references public.smollan_promoters(id) on delete set null,
  notes text not null default '',
  evidence_url text,
  created_at timestamptz not null default now()
);
create index if not exists smollan_goodie_distributions_quota_idx on public.smollan_goodie_distributions(quota_id, distribution_time);

create or replace view public.smollan_promoter_project_history as
select a.promoter_id,a.project_id,p.code as project_code,p.name as project_name,a.store_id,s.name as store_name,a.supervisor_id,
a.start_date as assignment_start,a.end_date as assignment_end,a.status as assignment_status,
count(att.id)::integer as attendance_records,
count(att.id) filter (where att.status = 'present')::integer as present_days,
count(att.id) filter (where att.status in ('absent','no_show'))::integer as absent_days,
min(att.attendance_date) as first_attendance,max(att.attendance_date) as last_attendance
from public.smollan_assignments a
join public.smollan_projects p on p.id=a.project_id
left join public.smollan_stores s on s.id=a.store_id
left join public.smollan_attendance att on att.assignment_id=a.id
group by a.promoter_id,a.project_id,p.code,p.name,a.store_id,s.name,a.supervisor_id,a.start_date,a.end_date,a.status;

alter table public.smollan_project_working_days enable row level security;
alter table public.smollan_project_tasks enable row level security;
alter table public.smollan_project_deliverables enable row level security;
alter table public.smollan_goodie_store_day_quotas enable row level security;
alter table public.smollan_goodie_distributions enable row level security;
grant select, insert, update, delete on public.smollan_project_working_days,public.smollan_project_tasks,public.smollan_project_deliverables,public.smollan_goodie_store_day_quotas,public.smollan_goodie_distributions to authenticated;
grant select on public.smollan_promoter_project_history to authenticated;

create policy "active members read project working days" on public.smollan_project_working_days for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage project working days" on public.smollan_project_working_days for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager')));
create policy "active members read project tasks" on public.smollan_project_tasks for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "project team manage tasks" on public.smollan_project_tasks for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations','supervisor'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations','supervisor')));
create policy "active members read project deliverables" on public.smollan_project_deliverables for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage project deliverables" on public.smollan_project_deliverables for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations')));
create policy "active members read goodie quotas" on public.smollan_goodie_store_day_quotas for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage goodie quotas" on public.smollan_goodie_store_day_quotas for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations')));
create policy "active members read goodie distributions" on public.smollan_goodie_distributions for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "authorized users log goodie distributions" on public.smollan_goodie_distributions for insert to authenticated with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','field_operations','supervisor','promoter')));
