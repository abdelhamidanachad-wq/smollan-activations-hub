-- Support traceable legacy imports that predate individual user attribution.
-- Application-created records continue to set created_by to auth.uid().
alter table public.smollan_projects alter column created_by drop not null;
alter table public.smollan_promoters add column if not exists source_employee_code text;

create unique index if not exists smollan_projects_code_uidx
  on public.smollan_projects(code);
create unique index if not exists smollan_clients_code_uidx
  on public.smollan_clients(code) where code is not null;
create unique index if not exists smollan_suppliers_legal_name_uidx
  on public.smollan_suppliers(legal_name);
create unique index if not exists smollan_stores_source_code_uidx
  on public.smollan_stores(source_code);
create unique index if not exists smollan_promoters_source_employee_code_uidx
  on public.smollan_promoters(source_employee_code) where source_employee_code is not null;
create unique index if not exists smollan_quotations_number_uidx
  on public.smollan_quotations(quotation_number) where quotation_number is not null;
