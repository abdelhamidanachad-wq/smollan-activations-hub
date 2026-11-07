-- Keep compensation, commercial costs, invoices and logistics data within relevant teams.
do $$
declare t text;
begin
 foreach t in array array[
  'smollan_activation_configs','smollan_activation_cost_items','smollan_dispatch_routes','smollan_dispatch_costs','smollan_invoice_register'
 ] loop
  execute format('drop policy if exists %I on public.%I',t||'_active_member_read',t);
  execute format('drop policy if exists %I on public.%I',t||'_staff_write',t);
 end loop;
end $$;

create policy "activation config team read" on public.smollan_activation_configs for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','finance','procurement_production')));
create policy "activation config team write" on public.smollan_activation_configs for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator')));

create policy "activation cost team read" on public.smollan_activation_cost_items for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "activation cost team write" on public.smollan_activation_cost_items for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));

create policy "dispatch operations read" on public.smollan_dispatch_routes for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','procurement_production')));
create policy "dispatch operations write" on public.smollan_dispatch_routes for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production')));

create policy "dispatch cost team read" on public.smollan_dispatch_costs for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "dispatch cost team write" on public.smollan_dispatch_costs for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production')));

create policy "invoice team read" on public.smollan_invoice_register for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','procurement_production','activation_coordinator')));
create policy "invoice finance write" on public.smollan_invoice_register for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance')));
