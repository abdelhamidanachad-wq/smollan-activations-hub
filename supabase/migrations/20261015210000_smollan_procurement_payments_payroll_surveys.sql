-- SMOLLAN PHP operations foundations: supplier purchasing, payments, payroll, field surveys.
-- Additive only. Existing imported business records are preserved.
create table if not exists public.smollan_suppliers (
 id uuid primary key default gen_random_uuid(),
 supplier_code text unique,
 legal_name text not null,
 tax_id text,
 contact_name text,
 contact_email text,
 contact_phone text,
 address text,
 city text,
 payment_terms text,
 status text not null default 'Active' check(status in ('Active','Inactive','Blocked')),
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists smollan_suppliers_name_idx on public.smollan_suppliers(lower(legal_name));

create table if not exists public.smollan_supplier_quotations (
 id uuid primary key default gen_random_uuid(),
 supplier_id uuid not null references public.smollan_suppliers(id),
 project_id uuid references public.smollan_projects(id),
 quotation_ref text,
 quotation_date date,
 expiry_date date,
 currency char(3) not null default 'MAD',
 subtotal numeric(14,2) not null default 0 check(subtotal>=0),
 tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0),
 delivery_days integer check(delivery_days is null or delivery_days>=0),
 status text not null default 'Received' check(status in ('Requested','Received','Under Review','Selected','Rejected','Expired')),
 attachment_ref text,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(expiry_date is null or quotation_date is null or expiry_date>=quotation_date)
);
create index if not exists smollan_supplier_quotations_project_idx on public.smollan_supplier_quotations(project_id,status);

create table if not exists public.smollan_supplier_quotation_lines (
 id uuid primary key default gen_random_uuid(),
 supplier_quotation_id uuid not null references public.smollan_supplier_quotations(id) on delete cascade,
 description text not null,
 quantity numeric(12,2) not null check(quantity>0),
 unit_price numeric(14,2) not null check(unit_price>=0),
 line_total numeric(14,2) generated always as (quantity*unit_price) stored
);

create table if not exists public.smollan_purchase_orders (
 id uuid primary key default gen_random_uuid(),
 po_number text not null unique,
 supplier_id uuid not null references public.smollan_suppliers(id),
 supplier_quotation_id uuid references public.smollan_supplier_quotations(id),
 project_id uuid not null references public.smollan_projects(id),
 status text not null default 'Draft' check(status in ('Draft','Pending Approval','Approved','Sent','Partially Received','Received','Cancelled','Closed')),
 currency char(3) not null default 'MAD',
 subtotal numeric(14,2) not null default 0 check(subtotal>=0),
 tax_amount numeric(14,2) not null default 0 check(tax_amount>=0),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0),
 requested_delivery_date date,
 approved_by uuid references auth.users(id),
 approved_at timestamptz,
 ordered_at timestamptz,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists smollan_purchase_orders_project_status_idx on public.smollan_purchase_orders(project_id,status);

create table if not exists public.smollan_purchase_order_lines (
 id uuid primary key default gen_random_uuid(),
 purchase_order_id uuid not null references public.smollan_purchase_orders(id) on delete cascade,
 description text not null,
 quantity numeric(12,2) not null check(quantity>0),
 unit_price numeric(14,2) not null check(unit_price>=0),
 line_total numeric(14,2) generated always as (quantity*unit_price) stored,
 received_quantity numeric(12,2) not null default 0 check(received_quantity>=0 and received_quantity<=quantity)
);

create table if not exists public.smollan_goods_receipts (
 id uuid primary key default gen_random_uuid(),
 receipt_number text not null unique,
 purchase_order_id uuid not null references public.smollan_purchase_orders(id),
 received_at timestamptz not null default now(),
 received_by uuid references auth.users(id),
 status text not null default 'Pending Inspection' check(status in ('Pending Inspection','Accepted','Partially Accepted','Rejected')),
 delivery_note_ref text,
 photo_ref text,
 notes text,
 created_at timestamptz not null default now()
);

create table if not exists public.smollan_goods_receipt_lines (
 id uuid primary key default gen_random_uuid(),
 goods_receipt_id uuid not null references public.smollan_goods_receipts(id) on delete cascade,
 purchase_order_line_id uuid not null references public.smollan_purchase_order_lines(id),
 delivered_quantity numeric(12,2) not null check(delivered_quantity>=0),
 accepted_quantity numeric(12,2) not null default 0 check(accepted_quantity>=0 and accepted_quantity<=delivered_quantity),
 notes text
);

create table if not exists public.smollan_payment_records (
 id uuid primary key default gen_random_uuid(),
 payment_number text not null unique,
 project_id uuid references public.smollan_projects(id),
 supplier_id uuid references public.smollan_suppliers(id),
 purchase_order_id uuid references public.smollan_purchase_orders(id),
 expense_id uuid references public.smollan_expenses(id),
 invoice_number text,
 payment_type text not null check(payment_type in ('Supplier','Payroll','Expense','Client Receipt','Other')),
 payment_method text check(payment_method in ('Bank Transfer','Cheque','Cash','Card','Other')),
 amount numeric(14,2) not null check(amount>0),
 currency char(3) not null default 'MAD',
 status text not null default 'Pending' check(status in ('Pending','Approved','Scheduled','Paid','Failed','Cancelled')),
 requested_date date not null default current_date,
 due_date date,
 paid_at timestamptz,
 bank_reference text,
 receipt_ref text,
 approved_by uuid references auth.users(id),
 approved_at timestamptz,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists smollan_payments_supplier_status_idx on public.smollan_payment_records(supplier_id,status,due_date);
create index if not exists smollan_payments_project_idx on public.smollan_payment_records(project_id,status);

create table if not exists public.smollan_payroll_runs (
 id uuid primary key default gen_random_uuid(),
 run_code text not null unique,
 period_start date not null,
 period_end date not null,
 payment_date date,
 status text not null default 'Draft' check(status in ('Draft','Pending Approval','Approved','Paid','Cancelled')),
 currency char(3) not null default 'MAD',
 total_gross numeric(14,2) not null default 0 check(total_gross>=0),
 total_deductions numeric(14,2) not null default 0 check(total_deductions>=0),
 total_net numeric(14,2) not null default 0 check(total_net>=0),
 approved_by uuid references auth.users(id),
 approved_at timestamptz,
 notes text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(period_end>=period_start)
);
create table if not exists public.smollan_payroll_lines (
 id uuid primary key default gen_random_uuid(),
 payroll_run_id uuid not null references public.smollan_payroll_runs(id) on delete cascade,
 promoter_id uuid not null references public.smollan_promoters(id),
 project_id uuid references public.smollan_projects(id),
 days_worked numeric(8,2) not null default 0 check(days_worked>=0),
 rate numeric(14,2) not null default 0 check(rate>=0),
 allowances numeric(14,2) not null default 0 check(allowances>=0),
 bonuses numeric(14,2) not null default 0 check(bonuses>=0),
 deductions numeric(14,2) not null default 0 check(deductions>=0),
 gross_amount numeric(14,2) not null default 0 check(gross_amount>=0),
 net_amount numeric(14,2) not null default 0 check(net_amount>=0),
 payment_status text not null default 'Pending' check(payment_status in ('Pending','Approved','Paid','On Hold')),
 payment_record_id uuid references public.smollan_payment_records(id),
 restricted_notes text,
 created_at timestamptz not null default now(),
 unique(payroll_run_id,promoter_id,project_id)
);
create index if not exists smollan_payroll_lines_promoter_idx on public.smollan_payroll_lines(promoter_id,payroll_run_id);

create table if not exists public.smollan_awards (
 id uuid primary key default gen_random_uuid(),
 promoter_id uuid not null references public.smollan_promoters(id),
 project_id uuid references public.smollan_projects(id),
 award_type text not null,
 awarded_on date not null default current_date,
 amount numeric(14,2) check(amount is null or amount>=0),
 points integer check(points is null or points>=0),
 reason text not null,
 approved_by uuid references auth.users(id),
 status text not null default 'Pending' check(status in ('Pending','Approved','Rejected','Paid','Granted')),
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now()
);

create table if not exists public.smollan_survey_forms (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 title text not null,
 form_type text not null check(form_type in ('Store Visit','Activation Check','Promoter Feedback','Client Feedback','Safety','Other')),
 questions jsonb not null default '[]'::jsonb,
 is_active boolean not null default true,
 opens_at timestamptz,
 closes_at timestamptz,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(closes_at is null or opens_at is null or closes_at>=opens_at)
);

create table if not exists public.smollan_survey_responses (
 id uuid primary key default gen_random_uuid(),
 form_id uuid not null references public.smollan_survey_forms(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id),
 promoter_id uuid references public.smollan_promoters(id),
 assignment_id uuid references public.smollan_assignments(id),
 store_id uuid references public.smollan_stores(id),
 answers jsonb not null default '{}'::jsonb,
 submitted_at timestamptz not null default now(),
 submitted_by uuid references auth.users(id),
 review_status text not null default 'Pending' check(review_status in ('Pending','Reviewed','Rejected')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 reviewer_notes text,
 photo_refs jsonb not null default '[]'::jsonb
);
create index if not exists smollan_survey_responses_project_idx on public.smollan_survey_responses(project_id,submitted_at desc);

-- RLS policies: no anonymous access; active and role-scoped membership only.
do $$
declare tbl text;
begin
  foreach tbl in array array[
    'smollan_suppliers','smollan_supplier_quotations','smollan_supplier_quotation_lines',
    'smollan_purchase_orders','smollan_purchase_order_lines','smollan_goods_receipts',
    'smollan_goods_receipt_lines','smollan_payment_records','smollan_payroll_runs',
    'smollan_payroll_lines','smollan_awards','smollan_survey_forms','smollan_survey_responses'
  ] loop
    execute format('alter table public.%I enable row level security',tbl);
    execute format('revoke all on public.%I from anon, authenticated',tbl);
  end loop;
end $$;

grant select,insert,update on public.smollan_suppliers,public.smollan_supplier_quotations,public.smollan_purchase_orders,public.smollan_goods_receipts,public.smollan_payment_records,public.smollan_payroll_runs,public.smollan_payroll_lines,public.smollan_awards,public.smollan_survey_forms,public.smollan_survey_responses to authenticated;
grant select,insert,update,delete on public.smollan_supplier_quotation_lines,public.smollan_purchase_order_lines,public.smollan_goods_receipt_lines to authenticated;

create policy "finance procurement read suppliers" on public.smollan_suppliers for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "procurement manage suppliers" on public.smollan_suppliers for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production')));

create policy "authorized users read supplier quotations" on public.smollan_supplier_quotations for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "procurement manage supplier quotations" on public.smollan_supplier_quotations for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production')));
create policy "authorized users read supplier quote lines" on public.smollan_supplier_quotation_lines for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "procurement manage supplier quote lines" on public.smollan_supplier_quotation_lines for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production')));

create policy "authorized users read POs" on public.smollan_purchase_orders for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "procurement manage POs" on public.smollan_purchase_orders for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production')));
create policy "authorized users read PO lines" on public.smollan_purchase_order_lines for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "procurement manage PO lines" on public.smollan_purchase_order_lines for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production')));

create policy "authorized users read goods receipts" on public.smollan_goods_receipts for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','field_operations')));
create policy "procurement manage goods receipts" on public.smollan_goods_receipts for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production','field_operations')));
create policy "authorized users read receipt lines" on public.smollan_goods_receipt_lines for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','field_operations')));
create policy "procurement manage receipt lines" on public.smollan_goods_receipt_lines for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','procurement_production','field_operations')));

create policy "finance read payment records" on public.smollan_payment_records for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')));
create policy "finance manage payment records" on public.smollan_payment_records for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')));

create policy "finance and HR read payroll runs" on public.smollan_payroll_runs for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator')));
create policy "finance and HR manage payroll runs" on public.smollan_payroll_runs for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator')));
create policy "finance and HR read payroll lines" on public.smollan_payroll_lines for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator')));
create policy "finance and HR manage payroll lines" on public.smollan_payroll_lines for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','hr_coordinator')));

create policy "authorized users read awards" on public.smollan_awards for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator','finance')));
create policy "managers manage awards" on public.smollan_awards for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator')));

create policy "active staff read survey forms" on public.smollan_survey_forms for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','read_only_client')));
create policy "coordinators manage survey forms" on public.smollan_survey_forms for all to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations')));
create policy "authorized staff read survey responses" on public.smollan_survey_responses for select to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','read_only_client')));
create policy "assigned field roles submit survey responses" on public.smollan_survey_responses for insert to authenticated with check (submitted_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','promoter')));
create policy "coordinators review survey responses" on public.smollan_survey_responses for update to authenticated using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations'))) with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations')));
