-- Activation design, staffing/payroll, production requirements, sourcing and dispatch.
-- Additive schema: existing operational records remain unchanged.
create table if not exists public.smollan_activation_configs (
  project_id uuid primary key references public.smollan_projects(id) on delete cascade,
  activation_type text not null default 'instore'
    check (activation_type in ('instore','street','roadshow','event','foodtruck','sampling','hybrid','other')),
  promoters_enabled boolean not null default true,
  tasting_enabled boolean not null default false,
  plv_enabled boolean not null default false,
  uniforms_enabled boolean not null default false,
  goodies_enabled boolean not null default false,
  tombola_enabled boolean not null default false,
  digital_game_enabled boolean not null default false,
  survey_enabled boolean not null default false,
  configuration jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_activation_staffing (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  store_id uuid references public.smollan_stores(id) on delete set null,
  city text,
  location_label text,
  promoter_count integer not null default 1 check (promoter_count between 0 and 500),
  salary_mode text not null default 'project' check (salary_mode in ('project','custom')),
  project_daily_salary numeric(12,2) check (project_daily_salary is null or project_daily_salary >= 0),
  custom_daily_salary numeric(12,2) check (custom_daily_salary is null or custom_daily_salary >= 0),
  shift_start time,
  shift_end time,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (store_id is not null or nullif(trim(city),'') is not null or nullif(trim(location_label),'') is not null)
);
create index if not exists smollan_activation_staffing_project_idx on public.smollan_activation_staffing(project_id,city,store_id);

create table if not exists public.smollan_activation_payroll_items (
  id uuid primary key default gen_random_uuid(),
  staffing_id uuid not null references public.smollan_activation_staffing(id) on delete cascade,
  promoter_id uuid references public.smollan_promoters(id) on delete set null,
  component_type text not null check (component_type in ('base_salary','transport','meal','launch','medical_test','documents','bonus','other')),
  description text not null,
  quantity numeric(10,2) not null default 1 check (quantity > 0),
  unit_amount numeric(12,2) not null default 0 check (unit_amount >= 0),
  currency char(3) not null default 'MAD',
  created_at timestamptz not null default now()
);
create index if not exists smollan_activation_payroll_staffing_idx on public.smollan_activation_payroll_items(staffing_id,promoter_id);

create table if not exists public.smollan_activation_material_requirements (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  category text not null check (category in ('tasting','plv','uniform','goodie','tombola','other')),
  item_name text not null,
  item_type text,
  quantity numeric(12,2) not null default 0 check (quantity >= 0),
  unit text not null default 'unit',
  specification text,
  unit_budget numeric(12,2) check (unit_budget is null or unit_budget >= 0),
  bat_status text check (bat_status in ('not_required','pending','confirmed','redo','rejected')),
  supplier_id uuid,
  include_in_quotation boolean not null default true,
  include_in_dispatch boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists smollan_activation_material_project_idx on public.smollan_activation_material_requirements(project_id,category);

create table if not exists public.smollan_activation_experiences (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  experience_type text not null check (experience_type in ('tombola','digital_game','customer_survey')),
  title text not null,
  public_slug text unique,
  public_url text,
  qr_asset_url text,
  configuration jsonb not null default '{}'::jsonb,
  is_published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  supplier_code text unique,
  contact_name text,
  email text,
  phone text,
  tax_id text,
  address text,
  payment_terms text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists smollan_suppliers_name_idx on public.smollan_suppliers(name);

create table if not exists public.smollan_supplier_quotations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  supplier_id uuid not null references public.smollan_suppliers(id),
  quotation_number text,
  received_date date not null default current_date,
  valid_until date,
  status text not null default 'received' check (status in ('requested','received','under_review','selected','rejected','expired')),
  currency char(3) not null default 'MAD',
  subtotal numeric(14,2) not null default 0 check (subtotal >= 0),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  total_amount numeric(14,2) not null default 0 check (total_amount >= 0),
  attachment_url text,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists smollan_supplier_quotes_project_idx on public.smollan_supplier_quotations(project_id,status);

create table if not exists public.smollan_supplier_quotation_lines (
  id uuid primary key default gen_random_uuid(),
  supplier_quotation_id uuid not null references public.smollan_supplier_quotations(id) on delete cascade,
  description text not null,
  quantity numeric(12,2) not null default 1 check (quantity > 0),
  unit text not null default 'unit',
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0),
  line_total numeric(14,2) generated always as (quantity * unit_price) stored
);

create table if not exists public.smollan_procurement_documents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  supplier_id uuid references public.smollan_suppliers(id),
  document_type text not null check (document_type in ('client_quote','supplier_quote_request','supplier_po','client_po_request','supplier_invoice','client_invoice')),
  document_number text not null,
  status text not null default 'draft' check (status in ('draft','sent','received','approved','rejected','partially_received','closed','paid')),
  issue_date date not null default current_date,
  due_date date,
  currency char(3) not null default 'MAD',
  amount numeric(14,2) not null default 0 check (amount >= 0),
  attachment_url text,
  related_document_id uuid references public.smollan_procurement_documents(id),
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(project_id,document_type,document_number)
);
create index if not exists smollan_procurement_docs_project_idx on public.smollan_procurement_documents(project_id,document_type,status);

create table if not exists public.smollan_dispatch_plans (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  name text not null,
  dispatch_type text not null default 'store_supply' check (dispatch_type in ('store_supply','roadshow','foodtruck','return_logistics','other')),
  status text not null default 'draft' check (status in ('draft','planned','in_transit','completed','cancelled')),
  start_date date,
  end_date date,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.smollan_dispatch_routes (
  id uuid primary key default gen_random_uuid(),
  dispatch_plan_id uuid not null references public.smollan_dispatch_plans(id) on delete cascade,
  transporter_name text not null,
  vehicle_type text,
  vehicle_registration text,
  driver_name text,
  driver_phone text,
  planned_date date,
  estimated_cost numeric(14,2) not null default 0 check (estimated_cost >= 0),
  actual_cost numeric(14,2) not null default 0 check (actual_cost >= 0),
  currency char(3) not null default 'MAD',
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.smollan_dispatch_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.smollan_dispatch_routes(id) on delete cascade,
  stop_order integer not null check (stop_order > 0),
  store_id uuid references public.smollan_stores(id) on delete set null,
  stop_name text not null,
  city text,
  address text,
  planned_arrival timestamptz,
  actual_arrival timestamptz,
  planned_departure timestamptz,
  delivery_status text not null default 'pending' check (delivery_status in ('pending','loaded','delivered','partial','failed','returned')),
  proof_url text,
  notes text,
  unique(route_id,stop_order)
);
create index if not exists smollan_dispatch_routes_plan_idx on public.smollan_dispatch_routes(dispatch_plan_id,planned_date);

create table if not exists public.smollan_finance_exports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.smollan_projects(id) on delete set null,
  export_format text not null check (export_format in ('csv_excel','sage_csv')),
  period_start date,
  period_end date,
  row_count integer not null default 0,
  file_name text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- Restrict all new operational records to active workspace members; write policies are role-scoped.
do $$
declare t text;
begin
 foreach t in array array[
  'smollan_activation_configs','smollan_activation_staffing','smollan_activation_payroll_items',
  'smollan_activation_material_requirements','smollan_activation_experiences','smollan_suppliers',
  'smollan_supplier_quotations','smollan_supplier_quotation_lines','smollan_procurement_documents',
  'smollan_dispatch_plans','smollan_dispatch_routes','smollan_dispatch_stops','smollan_finance_exports'
 ] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('grant select, insert, update, delete on public.%I to authenticated',t);
  execute format('create policy %I on public.%I for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active))',t||'_active_members_read',t);
  execute format('create policy %I on public.%I for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''finance'',''activation_coordinator'',''field_manager'',''field_operations'',''procurement_production''))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''finance'',''activation_coordinator'',''field_manager'',''field_operations'',''procurement_production'')))',t||'_authorized_write',t);
 end loop;
end $$;
