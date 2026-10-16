-- Per-project operating cycles, configurable KPIs and linked source documents.
-- Additive only: preserves existing operational records.
create table if not exists public.smollan_project_cycles (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  cycle_number integer not null default 1 check (cycle_number > 0),
  name text not null,
  start_date date,
  end_date date,
  cadence text not null default 'none' check (cadence in ('VSD','SD','daily','weekly','monthly','custom','none')),
  status text not null default 'planning' check (status in ('planning','ready','active','paused','completed','cancelled')),
  operating_days jsonb not null default '[]'::jsonb,
  specifications jsonb not null default '{}'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(project_id, cycle_number),
  check (start_date is null or end_date is null or end_date >= start_date)
);
create index if not exists smollan_project_cycles_project_status_idx
  on public.smollan_project_cycles(project_id, status, start_date);

create table if not exists public.smollan_project_kpis (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  kpi_key text not null,
  label text not null,
  description text,
  unit text not null default 'count',
  target numeric,
  warning_threshold numeric,
  calculation_key text not null default 'manual',
  enabled boolean not null default true,
  configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(project_id, kpi_key)
);
create index if not exists smollan_project_kpis_enabled_idx
  on public.smollan_project_kpis(project_id, enabled);

-- Keep the original Google Drive URL and where it came from. Never copy document
-- contents into the app; access remains governed by Google Drive sharing.
create table if not exists public.smollan_document_links (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.smollan_projects(id) on delete cascade,
  promoter_id uuid references public.smollan_promoters(id) on delete set null,
  store_id uuid references public.smollan_stores(id) on delete set null,
  category text not null check (category in (
    'cin','rib','quotation','purchase_order','invoice','payment_proof',
    'pec','contract','attendance_sheet','payroll','posm','goodies',
    'uniform','store_document','brief','report','other'
  )),
  title text not null,
  drive_url text not null check (drive_url ~ '^https?://'),
  source_workbook text,
  source_sheet text,
  source_cell text,
  external_reference text,
  document_date date,
  amount numeric,
  currency text not null default 'MAD',
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (project_id is not null or promoter_id is not null or store_id is not null or category in ('quotation','purchase_order','invoice','payment_proof','other'))
);
create index if not exists smollan_document_links_project_category_idx
  on public.smollan_document_links(project_id, category);
create index if not exists smollan_document_links_promoter_idx
  on public.smollan_document_links(promoter_id, category);
create index if not exists smollan_document_links_store_idx
  on public.smollan_document_links(store_id, category);
create unique index if not exists smollan_document_links_source_dedupe_idx
  on public.smollan_document_links(source_workbook, source_sheet, source_cell, drive_url)
  where source_workbook is not null and source_sheet is not null and source_cell is not null;

-- Promoter access is username-based in the app; authentication still belongs to
-- Supabase Auth. Password hashes are never stored in Smollan application tables.
create table if not exists public.smollan_promoter_logins (
  id uuid primary key default gen_random_uuid(),
  promoter_id uuid not null unique references public.smollan_promoters(id) on delete cascade,
  username text not null unique check (username ~ '^[A-Za-z0-9._-]{3,50}$'),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  enabled boolean not null default true,
  must_change_password boolean not null default true,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists smollan_promoter_logins_enabled_idx
  on public.smollan_promoter_logins(enabled, username);

create or replace function public.smollan_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists smollan_project_cycles_touch_updated_at on public.smollan_project_cycles;
create trigger smollan_project_cycles_touch_updated_at before update on public.smollan_project_cycles
for each row execute function public.smollan_touch_updated_at();
drop trigger if exists smollan_project_kpis_touch_updated_at on public.smollan_project_kpis;
create trigger smollan_project_kpis_touch_updated_at before update on public.smollan_project_kpis
for each row execute function public.smollan_touch_updated_at();
drop trigger if exists smollan_document_links_touch_updated_at on public.smollan_document_links;
create trigger smollan_document_links_touch_updated_at before update on public.smollan_document_links
for each row execute function public.smollan_touch_updated_at();
drop trigger if exists smollan_promoter_logins_touch_updated_at on public.smollan_promoter_logins;
create trigger smollan_promoter_logins_touch_updated_at before update on public.smollan_promoter_logins
for each row execute function public.smollan_touch_updated_at();
