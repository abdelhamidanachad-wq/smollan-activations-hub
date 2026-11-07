-- Let commercial and activation teams create and maintain project quotations.
drop policy if exists "activation teams manage quotations" on public.smollan_quotations;
create policy "activation teams manage quotations" on public.smollan_quotations for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','activation_coordinator','procurement_production')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','activation_coordinator','procurement_production')));

drop policy if exists "activation teams manage quotation lines" on public.smollan_quotation_lines;
create policy "activation teams manage quotation lines" on public.smollan_quotation_lines for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','activation_coordinator','procurement_production')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','finance','activation_coordinator','procurement_production')));
