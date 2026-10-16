-- Project setup, reporting links and assignment-bound attendance links.
create table if not exists public.smollan_store_supervisors (
  store_id uuid not null references public.smollan_stores(id) on delete cascade,
  supervisor_id uuid not null references public.smollan_supervisors(id) on delete cascade,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (store_id, supervisor_id)
);

-- Seed supervisor/store relationships from the historical project-store assignments.
insert into public.smollan_store_supervisors(store_id, supervisor_id, is_primary)
select distinct on (store_id, supervisor_id) store_id, supervisor_id, true
from public.smollan_project_stores
where supervisor_id is not null
on conflict (store_id, supervisor_id) do nothing;

create table if not exists public.smollan_project_modules (
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  module_key text not null check (module_key in ('goodies','plv','uniforms')),
  enabled boolean not null default true,
  configured_by uuid references auth.users(id),
  configured_at timestamptz not null default now(),
  primary key(project_id, module_key)
);

create table if not exists public.smollan_project_reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 180),
  summary text not null default '',
  metrics jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check(status in ('draft','published','archived')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists smollan_project_reports_project_idx
  on public.smollan_project_reports(project_id, created_at desc);

create table if not exists public.smollan_report_share_links (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.smollan_project_reports(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists smollan_report_share_links_report_idx
  on public.smollan_report_share_links(report_id);

create table if not exists public.smollan_attendance_links (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.smollan_assignments(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists smollan_attendance_links_assignment_idx
  on public.smollan_attendance_links(assignment_id, expires_at desc);

alter table public.smollan_store_supervisors enable row level security;
alter table public.smollan_project_modules enable row level security;
alter table public.smollan_project_reports enable row level security;
alter table public.smollan_report_share_links enable row level security;
alter table public.smollan_attendance_links enable row level security;

grant select, insert, update, delete on public.smollan_store_supervisors,
  public.smollan_project_modules, public.smollan_project_reports,
  public.smollan_report_share_links, public.smollan_attendance_links to authenticated;

create policy "active members read store supervisors" on public.smollan_store_supervisors
for select to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active)
);
create policy "coordinators manage store supervisors" on public.smollan_store_supervisors
for all to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))
) with check (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))
);

create policy "active members read project modules" on public.smollan_project_modules
for select to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active)
);
create policy "coordinators manage project modules" on public.smollan_project_modules
for all to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))
) with check (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))
);

create policy "active members read project reports" on public.smollan_project_reports
for select to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active)
);
create policy "coordinators manage project reports" on public.smollan_project_reports
for all to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','client_services'))
) with check (
  created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','client_services'))
);

create policy "active members manage report share links" on public.smollan_report_share_links
for all to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','client_services'))
) with check (
  created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','client_services'))
);

create policy "active members manage attendance links" on public.smollan_attendance_links
for all to authenticated using (
  exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor'))
) with check (
  created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor'))
);
