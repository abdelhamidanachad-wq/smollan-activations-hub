-- Activation configuration, commercial workflow, digital engagement and dispatch planning.
-- Additive schema. Existing projects, suppliers, payroll and survey records remain intact.

create table if not exists public.smollan_activation_configs (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null unique references public.smollan_projects(id) on delete cascade,
 activation_types text[] not null default '{}',
 promoters_enabled boolean not null default false,
 tasting_enabled boolean not null default false,
 plv_enabled boolean not null default false,
 uniforms_enabled boolean not null default false,
 goodies_enabled boolean not null default false,
 tombola_enabled boolean not null default false,
 digital_game_enabled boolean not null default false,
 customer_survey_enabled boolean not null default false,
 config_status text not null default 'draft' check(config_status in ('draft','review','approved','locked')),
 brief jsonb not null default '{}'::jsonb,
 created_by uuid references auth.users(id),
 approved_by uuid references auth.users(id),
 approved_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.smollan_activation_staffing (
 id uuid primary key default gen_random_uuid(),
 config_id uuid not null references public.smollan_activation_configs(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 store_id uuid references public.smollan_stores(id),
 city text,
 location_label text,
 role_label text not null default 'Promoter',
 headcount integer not null check(headcount>=0),
 salary_mode text not null default 'project_rate' check(salary_mode in ('project_rate','individual_rate')),
 project_daily_rate numeric(12,2) not null default 0 check(project_daily_rate>=0),
 notes text,
 created_at timestamptz not null default now()
);
create index if not exists smollan_activation_staffing_project_idx on public.smollan_activation_staffing(project_id,city,store_id);
create table if not exists public.smollan_activation_pay_components (
 id uuid primary key default gen_random_uuid(),
 config_id uuid not null references public.smollan_activation_configs(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 promoter_id uuid references public.smollan_promoters(id),
 component_type text not null check(component_type in ('salary','transport','meal','medical_test','document_fee','bonus','other')),
 label text not null,
 quantity numeric(10,2) not null default 1 check(quantity>=0),
 unit_amount numeric(12,2) not null default 0 check(unit_amount>=0),
 is_per_promoter boolean not null default true,
 notes text,
 created_at timestamptz not null default now()
);
create table if not exists public.smollan_activation_requirements (
 id uuid primary key default gen_random_uuid(),
 config_id uuid not null references public.smollan_activation_configs(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 module_key text not null check(module_key in ('tasting','plv','uniforms','goodies','tombola','other')),
 item_name text not null,
 item_type text,
 specification text,
 quantity numeric(12,2) not null default 0 check(quantity>=0),
 unit text not null default 'unit',
 unit_cost numeric(12,2) not null default 0 check(unit_cost>=0),
 supplier_id uuid references public.smollan_suppliers(id),
 required_by date,
 notes text,
 created_at timestamptz not null default now()
);
create index if not exists smollan_activation_requirements_project_idx on public.smollan_activation_requirements(project_id,module_key);

create table if not exists public.smollan_artwork_approvals (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 requirement_id uuid references public.smollan_activation_requirements(id) on delete cascade,
 material_name text not null,
 artwork_ref text,
 proof_ref text,
 status text not null default 'pending' check(status in ('pending','bat_to_validate','approved','rework_required','rejected')),
 version integer not null default 1 check(version>0),
 feedback text,
 submitted_at timestamptz,
 decided_by uuid references auth.users(id),
 decided_at timestamptz,
 created_at timestamptz not null default now()
);

create table if not exists public.smollan_client_quotations (
 id uuid primary key default gen_random_uuid(),
 quotation_number text not null unique,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 client_id uuid not null references public.smollan_clients(id),
 version integer not null default 1 check(version>0),
 status text not null default 'draft' check(status in ('draft','internal_review','sent_to_client','under_negotiation','approved','rejected','expired','cancelled')),
 currency char(3) not null default 'MAD',
 subtotal numeric(14,2) not null default 0 check(subtotal>=0),
 discount_amount numeric(14,2) not null default 0 check(discount_amount>=0),
 tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0),
 valid_until date,
 sent_at timestamptz,
 client_decision_at timestamptz,
 attachment_ref text,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(project_id,version)
);
create table if not exists public.smollan_client_quotation_lines (
 id uuid primary key default gen_random_uuid(),
 quotation_id uuid not null references public.smollan_client_quotations(id) on delete cascade,
 category text not null check(category in ('staffing','tasting_consumables','plv','uniforms','goodies','tombola','digital_game','survey','logistics','management','other')),
 description text not null,
 quantity numeric(12,2) not null check(quantity>=0),
 unit text not null default 'unit',
 unit_cost numeric(14,2) not null default 0 check(unit_cost>=0),
 unit_price numeric(14,2) not null default 0 check(unit_price>=0),
 line_cost numeric(14,2) generated always as (quantity*unit_cost) stored,
 line_total numeric(14,2) generated always as (quantity*unit_price) stored,
 supplier_id uuid references public.smollan_suppliers(id),
 source_requirement_id uuid references public.smollan_activation_requirements(id) on delete set null
);
create index if not exists smollan_client_quotes_project_idx on public.smollan_client_quotations(project_id,status,created_at desc);

create table if not exists public.smollan_supplier_invoices (
 id uuid primary key default gen_random_uuid(),
 supplier_id uuid not null references public.smollan_suppliers(id),
 project_id uuid references public.smollan_projects(id),
 purchase_order_id uuid references public.smollan_purchase_orders(id),
 invoice_number text not null,
 invoice_date date,
 due_date date,
 currency char(3) not null default 'MAD',
 subtotal numeric(14,2) not null default 0 check(subtotal>=0),
 tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0),
 status text not null default 'received' check(status in ('received','under_review','matched','disputed','approved','partially_paid','paid','rejected')),
 attachment_ref text,
 sage_reference text,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(supplier_id,invoice_number)
);
create table if not exists public.smollan_client_invoices (
 id uuid primary key default gen_random_uuid(),
 invoice_number text not null unique,
 client_id uuid not null references public.smollan_clients(id),
 project_id uuid not null references public.smollan_projects(id),
 quotation_id uuid references public.smollan_client_quotations(id),
 purchase_order_ref text,
 invoice_date date not null default current_date,
 due_date date,
 currency char(3) not null default 'MAD',
 subtotal numeric(14,2) not null default 0 check(subtotal>=0),
 tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0),
 status text not null default 'draft' check(status in ('draft','issued','sent','partially_paid','paid','overdue','cancelled')),
 attachment_ref text,
 sage_reference text,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.smollan_dispatch_plans (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 plan_name text not null,
 dispatch_type text not null default 'store_supply' check(dispatch_type in ('store_supply','roadshow','food_truck','returns','event')),
 status text not null default 'draft' check(status in ('draft','planned','approved','in_progress','completed','cancelled')),
 start_date date,
 end_date date,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.smollan_dispatch_vehicles (
 id uuid primary key default gen_random_uuid(),
 dispatch_plan_id uuid not null references public.smollan_dispatch_plans(id) on delete cascade,
 transporter_name text not null,
 vehicle_type text,
 vehicle_registration text,
 driver_name text,
 driver_phone text,
 capacity_description text,
 fixed_cost numeric(12,2) not null default 0 check(fixed_cost>=0),
 cost_per_km numeric(12,2) not null default 0 check(cost_per_km>=0),
 notes text
);
create table if not exists public.smollan_dispatch_stops (
 id uuid primary key default gen_random_uuid(),
 vehicle_id uuid not null references public.smollan_dispatch_vehicles(id) on delete cascade,
 sequence_no integer not null check(sequence_no>0),
 store_id uuid references public.smollan_stores(id),
 stop_name text not null,
 address text,
 city text,
 planned_arrival timestamptz,
 actual_arrival timestamptz,
 distance_km numeric(10,2) check(distance_km is null or distance_km>=0),
 stop_cost numeric(12,2) not null default 0 check(stop_cost>=0),
 status text not null default 'planned' check(status in ('planned','loaded','delivered','failed','skipped','returned')),
 delivery_note_ref text,
 proof_ref text,
 notes text,
 unique(vehicle_id,sequence_no)
);
create table if not exists public.smollan_dispatch_items (
 id uuid primary key default gen_random_uuid(),
 dispatch_plan_id uuid not null references public.smollan_dispatch_plans(id) on delete cascade,
 requirement_id uuid references public.smollan_activation_requirements(id),
 item_name text not null,
 quantity numeric(12,2) not null check(quantity>=0),
 unit text not null default 'unit',
 origin_label text,
 destination_store_id uuid references public.smollan_stores(id),
 delivered_quantity numeric(12,2) not null default 0 check(delivered_quantity>=0 and delivered_quantity<=quantity),
 notes text
);

create table if not exists public.smollan_digital_games (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 title text not null,
 game_type text not null default 'spin_wheel' check(game_type in ('spin_wheel','quiz','scratch_card','instant_win','custom')),
 public_slug text not null unique,
 config jsonb not null default '{}'::jsonb,
 prize_rules jsonb not null default '[]'::jsonb,
 qr_asset_ref text,
 is_active boolean not null default false,
 starts_at timestamptz,
 ends_at timestamptz,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.smollan_digital_game_entries (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.smollan_digital_games(id) on delete cascade,
 participant_ref text,
 consent_given boolean not null default false,
 result jsonb not null default '{}'::jsonb,
 entered_at timestamptz not null default now()
);
create table if not exists public.smollan_tombola_entries (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 store_id uuid references public.smollan_stores(id),
 draw_code text not null,
 participant_ref text,
 consent_given boolean not null default false,
 entry_data jsonb not null default '{}'::jsonb,
 prize_label text,
 is_winner boolean not null default false,
 entered_at timestamptz not null default now()
);

-- Sensitive commercial and operational tables are accessible only to authenticated,
-- active SMOLLAN members. Public participation uses dedicated app endpoints, not table grants.
do $$ declare t text; begin
 foreach t in array array[
 'smollan_activation_configs','smollan_activation_staffing','smollan_activation_pay_components',
 'smollan_activation_requirements','smollan_artwork_approvals','smollan_client_quotations',
 'smollan_client_quotation_lines','smollan_supplier_invoices','smollan_client_invoices',
 'smollan_dispatch_plans','smollan_dispatch_vehicles','smollan_dispatch_stops','smollan_dispatch_items',
 'smollan_digital_games','smollan_digital_game_entries','smollan_tombola_entries'
 ] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon, authenticated',t);
 end loop;
end $$;
grant select,insert,update,delete on public.smollan_activation_configs,public.smollan_activation_staffing,
 public.smollan_activation_pay_components,public.smollan_activation_requirements,public.smollan_artwork_approvals,
 public.smollan_client_quotations,public.smollan_client_quotation_lines,public.smollan_supplier_invoices,
 public.smollan_client_invoices,public.smollan_dispatch_plans,public.smollan_dispatch_vehicles,
 public.smollan_dispatch_stops,public.smollan_dispatch_items,public.smollan_digital_games,
 public.smollan_digital_game_entries,public.smollan_tombola_entries to authenticated;

do $$ declare t text; begin
 foreach t in array array[
 'smollan_activation_configs','smollan_activation_staffing','smollan_activation_pay_components',
 'smollan_activation_requirements','smollan_artwork_approvals','smollan_client_quotations',
 'smollan_client_quotation_lines','smollan_supplier_invoices','smollan_client_invoices',
 'smollan_dispatch_plans','smollan_dispatch_vehicles','smollan_dispatch_stops','smollan_dispatch_items',
 'smollan_digital_games','smollan_digital_game_entries','smollan_tombola_entries'
 ] loop
  execute format('create policy %I on public.%I for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active)) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active))', 'active_member_access_'||t,t);
 end loop;
end $$;

-- Commercial follow-up, client PO intake and finance-system exchange metadata.
create table if not exists public.smollan_supplier_followups (
 id uuid primary key default gen_random_uuid(),
 supplier_quotation_id uuid not null references public.smollan_supplier_quotations(id) on delete cascade,
 followup_type text not null check(followup_type in ('request_sent','reminder','quotation_received','clarification','negotiation','selected','rejected')),
 occurred_at timestamptz not null default now(),
 next_followup_at timestamptz,
 contact_name text,
 contact_channel text,
 notes text,
 created_by uuid references auth.users(id)
);
create table if not exists public.smollan_client_po_requests (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 client_id uuid not null references public.smollan_clients(id),
 quotation_id uuid references public.smollan_client_quotations(id),
 request_number text not null unique,
 requested_at timestamptz not null default now(),
 expected_by date,
 received_po_number text,
 received_at timestamptz,
 attachment_ref text,
 status text not null default 'draft' check(status in ('draft','sent_to_client','reminder_due','received','rejected','cancelled')),
 notes text,
 created_by uuid references auth.users(id)
);
create table if not exists public.smollan_external_integrations (
 id uuid primary key default gen_random_uuid(),
 provider text not null check(provider in ('sage','google_maps','email','whatsapp','other')),
 display_name text not null,
 is_enabled boolean not null default false,
 secret_env_name text,
 config jsonb not null default '{}'::jsonb,
 last_tested_at timestamptz,
 last_test_status text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(provider,display_name)
);
create table if not exists public.smollan_finance_exchange_batches (
 id uuid primary key default gen_random_uuid(),
 provider text not null default 'sage' check(provider in ('sage','excel','other')),
 direction text not null check(direction in ('import','export')),
 entity_type text not null check(entity_type in ('suppliers','supplier_invoices','client_invoices','payments','payroll','purchase_orders','chart_of_accounts','other')),
 file_ref text,
 status text not null default 'prepared' check(status in ('prepared','processing','completed','failed','partially_completed')),
 row_count integer not null default 0 check(row_count>=0),
 success_count integer not null default 0 check(success_count>=0),
 error_count integer not null default 0 check(error_count>=0),
 mapping jsonb not null default '{}'::jsonb,
 error_report_ref text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
alter table public.smollan_supplier_followups enable row level security;
alter table public.smollan_client_po_requests enable row level security;
alter table public.smollan_external_integrations enable row level security;
alter table public.smollan_finance_exchange_batches enable row level security;
revoke all on public.smollan_supplier_followups,public.smollan_client_po_requests,public.smollan_external_integrations,public.smollan_finance_exchange_batches from anon,authenticated;
grant select,insert,update,delete on public.smollan_supplier_followups,public.smollan_client_po_requests,public.smollan_external_integrations,public.smollan_finance_exchange_batches to authenticated;
create policy "active procurement finance access" on public.smollan_supplier_followups for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance','procurement')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance','procurement')));
create policy "active procurement finance access client po" on public.smollan_client_po_requests for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance','procurement')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','finance','procurement')));
create policy "platform admins manage integrations" on public.smollan_external_integrations for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership')));
create policy "finance team manages exchange batches" on public.smollan_finance_exchange_batches for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')));
