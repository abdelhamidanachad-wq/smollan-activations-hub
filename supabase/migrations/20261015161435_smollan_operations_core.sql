-- Applied to the dedicated SMOLLAN project on 2026-10-15.
create extension if not exists pgcrypto;
create type public.smollan_role as enum ('platform_admin','leadership','activation_coordinator','field_operations','finance','procurement_production','merchandising','supervisor','read_only_client');
create type public.project_service_type as enum ('permanent_promoters','activation','production_only','in_store_animation','merchandising');
create type public.project_cadence as enum ('VSD','SD','none');
create type public.project_status as enum ('lead','brief_received','planning','in_progress','on_hold','completed','archived');
create type public.task_status as enum ('todo','in_progress','waiting_approval','blocked','done','cancelled');

create table public.smollan_memberships (
 user_id uuid primary key references auth.users(id) on delete cascade,
 email text not null check (lower(email) like '%@smollan.com'),
 display_name text not null default '',
 role public.smollan_role not null default 'read_only_client',
 is_active boolean not null default false,
 approved_by uuid references auth.users(id), approved_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_clients (
 id uuid primary key default gen_random_uuid(), name text not null, code text unique,
 account_owner uuid references auth.users(id), contact_name text, contact_email text,
 contact_phone text, notes text, created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_projects (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 client_id uuid not null references public.smollan_clients(id), name text not null,
 service_type public.project_service_type not null, cadence public.project_cadence not null default 'none',
 status public.project_status not null default 'lead', start_date date, end_date date,
 cities text[] not null default '{}', owner_id uuid references auth.users(id),
 budget numeric(14,2), currency char(3) not null default 'MAD',
 drive_url text, calendar_url text, whatsapp_group_url text,
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(end_date is null or start_date is null or end_date >= start_date),
 check(budget is null or budget >= 0)
);
create index smollan_projects_client_status_idx on public.smollan_projects(client_id,status);
create index smollan_projects_dates_idx on public.smollan_projects(start_date,end_date);
create table public.smollan_tasks (
 id uuid primary key default gen_random_uuid(), project_id uuid references public.smollan_projects(id) on delete cascade,
 title text not null check(char_length(trim(title)) between 2 and 240), description text,
 status public.task_status not null default 'todo', assigned_to uuid references auth.users(id),
 due_at timestamptz, priority smallint not null default 2 check(priority between 1 and 4),
 created_by uuid not null references auth.users(id), completed_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index smollan_tasks_assignee_due_idx on public.smollan_tasks(assigned_to,due_at) where status not in ('done','cancelled');
create index smollan_tasks_project_status_idx on public.smollan_tasks(project_id,status);
create table public.smollan_audit_events (
 id bigint generated always as identity primary key, actor_id uuid references auth.users(id),
 action text not null, entity_type text not null, entity_id uuid, summary text not null,
 metadata jsonb not null default '{}', created_at timestamptz not null default now()
);
alter table public.smollan_memberships enable row level security;
alter table public.smollan_clients enable row level security;
alter table public.smollan_projects enable row level security;
alter table public.smollan_tasks enable row level security;
alter table public.smollan_audit_events enable row level security;
revoke all on public.smollan_memberships,public.smollan_clients,public.smollan_projects,public.smollan_tasks,public.smollan_audit_events from anon,authenticated;
grant select on public.smollan_memberships to authenticated;
grant select,insert,update on public.smollan_clients,public.smollan_projects,public.smollan_tasks to authenticated;
grant select,insert on public.smollan_audit_events to authenticated;
create policy "member reads own membership" on public.smollan_memberships for select to authenticated using(user_id=auth.uid());
create policy "active members read clients" on public.smollan_clients for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "business roles write clients" on public.smollan_clients for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance')));
create policy "active members read projects" on public.smollan_projects for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "project leads write projects" on public.smollan_projects for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising')));
create policy "active members read tasks" on public.smollan_tasks for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "active members create tasks" on public.smollan_tasks for insert to authenticated with check(created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "assignees or coordinators update tasks" on public.smollan_tasks for update to authenticated using(assigned_to=auth.uid() or exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations'))) with check(assigned_to=auth.uid() or exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations')));
create policy "leadership reads audit" on public.smollan_audit_events for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership')));
create policy "users append own audit events" on public.smollan_audit_events for insert to authenticated with check(actor_id=auth.uid());
