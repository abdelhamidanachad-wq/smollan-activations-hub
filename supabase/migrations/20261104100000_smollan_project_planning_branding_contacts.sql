-- Project scheduling, per-project visual identity and client stakeholder directory.
-- Additive migration; existing client/project records retain safe defaults.
alter table public.smollan_clients
  add column if not exists logo_url text,
  add column if not exists background_url text,
  add column if not exists brand_color text not null default '#1D5D52'
    check (brand_color ~ '^#[0-9A-Fa-f]{6}$');

create table if not exists public.smollan_client_contacts (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.smollan_clients(id) on delete cascade,
  contact_role text not null check (contact_role in ('trade_marketing','procurement','field','commercial_direction','other')),
  full_name text not null,
  email text,
  phone text,
  is_primary boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (email is null or email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$')
);
create index if not exists smollan_client_contacts_client_role_idx
  on public.smollan_client_contacts(client_id, contact_role, is_primary desc);

create table if not exists public.smollan_project_settings (
  project_id uuid primary key references public.smollan_projects(id) on delete cascade,
  planning_mode text not null default 'none'
    check (planning_mode in ('VSD','SD','weekdays','custom','daily','weekly','none')),
  operating_days smallint[] not null default '{}',
  brand_color text not null default '#1D5D52'
    check (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_url text,
  background_url text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (operating_days <@ array[1,2,3,4,5,6,7]::smallint[])
);
create index if not exists smollan_project_settings_planning_idx
  on public.smollan_project_settings(planning_mode);

alter table public.smollan_client_contacts enable row level security;
alter table public.smollan_project_settings enable row level security;
grant select, insert, update, delete on public.smollan_client_contacts, public.smollan_project_settings to authenticated;

create policy "active members read client contacts"
  on public.smollan_client_contacts for select to authenticated
  using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "platform admins manage client contacts"
  on public.smollan_client_contacts for all to authenticated
  using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator')))
  with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator')));
create policy "active members read project settings"
  on public.smollan_project_settings for select to authenticated
  using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "project admins manage project settings"
  on public.smollan_project_settings for all to authenticated
  using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager')))
  with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager')));
