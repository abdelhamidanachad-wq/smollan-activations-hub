-- Secure staging for legacy payroll sheets that contain employee identifiers and salary data.
alter table public.smollan_promoters add column if not exists source_cin_hash text;
create unique index if not exists smollan_promoters_source_cin_hash_uidx
  on public.smollan_promoters(source_cin_hash) where source_cin_hash is not null;

alter table public.smollan_promoter_private_details
  add column if not exists cnss_number_ciphertext text;

create table if not exists public.smollan_payroll_import_staging (
  id uuid primary key default gen_random_uuid(),
  source_file text not null,
  source_sheet text not null,
  source_row_number integer not null,
  source_site text,
  source_employee_code text,
  source_full_name text not null,
  job_title text,
  payment_method text,
  promoter_id uuid references public.smollan_promoters(id) on delete set null,
  project_id uuid references public.smollan_projects(id) on delete set null,
  national_id_ciphertext text,
  cnss_number_ciphertext text,
  daily_rate numeric not null default 0,
  days_worked numeric not null default 0,
  base_salary numeric not null default 0,
  paid_leave numeric not null default 0,
  transport_allowance numeric not null default 0,
  meal_allowance numeric not null default 0,
  gross_amount numeric not null default 0,
  deductions numeric not null default 0,
  net_amount numeric not null default 0,
  invoice_011 numeric not null default 0,
  invoice_775 numeric not null default 0,
  invoice_281 numeric not null default 0,
  total_billed numeric not null default 0,
  currency char(3) not null default 'MAD',
  status text not null default 'Review required',
  notes text,
  created_at timestamptz not null default now(),
  unique(source_file,source_sheet,source_row_number)
);

alter table public.smollan_payroll_import_staging enable row level security;
grant select,insert,update,delete on public.smollan_payroll_import_staging to authenticated;

drop policy if exists "finance and HR manage payroll import staging" on public.smollan_payroll_import_staging;
create policy "finance and HR manage payroll import staging"
on public.smollan_payroll_import_staging
for all to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','finance','hr_coordinator')
))
with check (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','finance','hr_coordinator')
));
