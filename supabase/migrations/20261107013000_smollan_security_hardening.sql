-- Harden newly exposed SMOLLAN operational tables and function privileges.
-- All access is membership- and role-scoped; no private employee records are public.

alter table public.smollan_document_links enable row level security;
alter table public.smollan_project_cycles enable row level security;
alter table public.smollan_project_kpis enable row level security;
alter table public.smollan_promoter_logins enable row level security;

grant select, insert, update, delete on public.smollan_document_links to authenticated;
grant select, insert, update, delete on public.smollan_project_cycles to authenticated;
grant select, insert, update, delete on public.smollan_project_kpis to authenticated;
grant select, insert, update, delete on public.smollan_promoter_logins to authenticated;

drop policy if exists "staff read document links" on public.smollan_document_links;
create policy "staff read document links" on public.smollan_document_links
for select to authenticated
using (
  exists (
    select 1 from public.smollan_memberships m
    where m.user_id = auth.uid() and m.is_active
      and (
        (category in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','leadership','hr_coordinator'))
        or
        (category not in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager','supervisor','finance','procurement_production','merchandising','hr_coordinator'))
      )
  )
);
drop policy if exists "staff manage document links" on public.smollan_document_links;
create policy "staff manage document links" on public.smollan_document_links
for all to authenticated
using (
  exists (
    select 1 from public.smollan_memberships m
    where m.user_id = auth.uid() and m.is_active
      and (
        (category in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','hr_coordinator'))
        or
        (category not in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager','finance','procurement_production','hr_coordinator'))
      )
  )
)
with check (
  exists (
    select 1 from public.smollan_memberships m
    where m.user_id = auth.uid() and m.is_active
      and (
        (category in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','hr_coordinator'))
        or
        (category not in ('cin','rib','pec','payroll','contract')
          and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager','finance','procurement_production','hr_coordinator'))
      )
  )
);

drop policy if exists "active staff read project cycles" on public.smollan_project_cycles;
create policy "active staff read project cycles" on public.smollan_project_cycles
for select to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager','supervisor','finance','procurement_production')
));
drop policy if exists "coordinators manage project cycles" on public.smollan_project_cycles;
create policy "coordinators manage project cycles" on public.smollan_project_cycles
for all to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager')
))
with check (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager')
));

drop policy if exists "active staff read project kpis" on public.smollan_project_kpis;
create policy "active staff read project kpis" on public.smollan_project_kpis
for select to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager','supervisor','finance','procurement_production')
));
drop policy if exists "coordinators manage project kpis" on public.smollan_project_kpis;
create policy "coordinators manage project kpis" on public.smollan_project_kpis
for all to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager')
))
with check (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','field_manager')
));

drop policy if exists "hr read promoter logins" on public.smollan_promoter_logins;
create policy "hr read promoter logins" on public.smollan_promoter_logins
for select to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','leadership','hr_coordinator')
));
drop policy if exists "hr manage promoter logins" on public.smollan_promoter_logins;
create policy "hr manage promoter logins" on public.smollan_promoter_logins
for all to authenticated
using (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','hr_coordinator')
))
with check (exists (
  select 1 from public.smollan_memberships m
  where m.user_id=auth.uid() and m.is_active
    and m.role in ('platform_admin','hr_coordinator')
));

-- A view must obey the caller's underlying table grants and RLS.
alter view public.smollan_promoter_project_history set (security_invoker = true);
grant select on public.smollan_promoter_project_history to authenticated;

-- Trigger functions do not need to be directly callable over the Data API.
alter function public.smollan_touch_updated_at() set search_path = pg_catalog;
revoke all on function public.smollan_touch_updated_at() from public, anon, authenticated;

-- The first-admin bootstrap and admin predicate are only for authenticated callers.
alter function public.smollan_bootstrap_first_admin() set search_path = pg_catalog;
revoke all on function public.smollan_bootstrap_first_admin() from public, anon;
grant execute on function public.smollan_bootstrap_first_admin() to authenticated;

alter function public.smollan_is_platform_admin() set search_path = pg_catalog;
revoke all on function public.smollan_is_platform_admin() from public, anon;
grant execute on function public.smollan_is_platform_admin() to authenticated;

-- Event triggers run under PostgreSQL's event-trigger mechanism, not RPC callers.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
