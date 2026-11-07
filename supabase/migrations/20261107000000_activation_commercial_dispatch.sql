-- SMOLLAN activation setup, commercial workflow and dispatch planning.
-- Apply through the Supabase SQL editor or your normal migration pipeline.

create extension if not exists pgcrypto;

alter table public.smollan_quotations
  add column if not exists quotation_scope text,
  add column if not exists supplier_name text,
  add column if not exists due_date date,
  add column if not exists followup_date date,
  add column if not exists comparison_result text,
  add column if not exists followup_notes text;

create table if not exists public.smollan_activation_configs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  activation_type text not null,
  promoters_required text,
  promoter_count integer not null default 0 check (promoter_count >= 0),
  staffing_plan text,
  payroll_model text,
  base_salary numeric(12,2),
  allowances_json text,
  tasting_required text,
  tasting_items_json text,
  plv_required text,
  plv_items_json text,
  bat_status text,
  uniforms_required text,
  uniform_details text,
  goodies_required text,
  goodies_details text,
  tombola_enabled text,
  digital_game_enabled text,
  qr_url text,
  survey_enabled text,
  survey_questions text,
  status text not null default 'Draft',
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_activation_cost_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  quotation_id uuid references public.smollan_quotations(id) on delete set null,
  category text not null,
  item_name text not null,
  specification text,
  quantity numeric(12,2) not null default 0 check (quantity >= 0),
  unit text,
  supplier_name text,
  unit_cost numeric(12,2),
  client_unit_price numeric(12,2),
  supplier_quote_status text not null default 'Not requested',
  client_quote_status text not null default 'Draft',
  notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_dispatch_routes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  route_name text not null,
  dispatch_date date,
  transporter_name text not null,
  driver_name text,
  vehicle_registration text,
  vehicle_type text,
  origin text,
  destination text,
  stops_json text,
  planned_cost numeric(12,2) not null default 0,
  actual_cost numeric(12,2) not null default 0,
  cost_reference text,
  status text not null default 'Draft',
  proof_url text,
  notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_dispatch_costs (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.smollan_dispatch_routes(id) on delete cascade,
  cost_type text not null,
  description text not null,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  supplier_name text,
  invoice_reference text,
  payment_status text,
  notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.smollan_purchase_orders (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  po_direction text not null,
  supplier_name text not null,
  po_number text not null,
  issue_date date,
  expected_date date,
  amount numeric(12,2) not null default 0,
  status text not null default 'Draft',
  document_url text,
  followup_notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Extend the existing PO workflow rather than shadowing the established supplier/PO tables.
alter table public.smollan_purchase_orders alter column supplier_id drop not null;
alter table public.smollan_purchase_orders
  add column if not exists po_direction text not null default 'PO sent to supplier',
  add column if not exists counterparty_name text,
  add column if not exists issue_date date,
  add column if not exists document_url text,
  add column if not exists followup_notes text;

create table if not exists public.smollan_invoice_register (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  invoice_direction text not null,
  counterparty text not null,
  invoice_number text not null,
  invoice_date date,
  due_date date,
  amount numeric(12,2) not null default 0,
  status text not null default 'Received',
  document_url text,
  sage_reference text,
  excel_batch_reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists smollan_activation_configs_project_idx on public.smollan_activation_configs(project_id);
create index if not exists smollan_activation_cost_items_project_idx on public.smollan_activation_cost_items(project_id);
create index if not exists smollan_dispatch_routes_project_date_idx on public.smollan_dispatch_routes(project_id, dispatch_date);
create index if not exists smollan_dispatch_costs_route_idx on public.smollan_dispatch_costs(route_id);
create index if not exists smollan_purchase_orders_project_idx on public.smollan_purchase_orders(project_id);
create index if not exists smollan_invoice_register_project_due_idx on public.smollan_invoice_register(project_id, due_date);

-- All active members can read shared operational records; read-only client roles
-- cannot create, edit or delete internal commercial/dispatch records.
do $$
declare t text;
begin
  foreach t in array array[
    'smollan_activation_configs',
    'smollan_activation_cost_items',
    'smollan_dispatch_routes',
    'smollan_dispatch_costs',
    'smollan_purchase_orders',
    'smollan_invoice_register'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_active_member_read', t);
    execute format('create policy %I on public.%I for select to authenticated using (exists (select 1 from public.smollan_memberships m where m.user_id = auth.uid() and m.is_active = true))', t || '_active_member_read', t);
    execute format('drop policy if exists %I on public.%I', t || '_staff_write', t);
    execute format('create policy %I on public.%I for all to authenticated using (exists (select 1 from public.smollan_memberships m where m.user_id = auth.uid() and m.is_active = true and m.role <> ''read_only_client'')) with check (exists (select 1 from public.smollan_memberships m where m.user_id = auth.uid() and m.is_active = true and m.role <> ''read_only_client''))', t || '_staff_write', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;
