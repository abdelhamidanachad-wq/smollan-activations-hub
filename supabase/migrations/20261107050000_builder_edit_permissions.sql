-- Keep creator ownership on insert while allowing authorized staff to revise shared builders.
drop policy if exists "coordinators manage project forms" on public.smollan_project_forms;
create policy "coordinators insert project forms" on public.smollan_project_forms for insert to authenticated
with check (created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "coordinators update project forms" on public.smollan_project_forms for update to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "coordinators delete project forms" on public.smollan_project_forms for delete to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));

drop policy if exists "authorized staff manage digital games" on public.smollan_digital_games;
create policy "authorized staff insert digital games" on public.smollan_digital_games for insert to authenticated
with check (created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "authorized staff update digital games" on public.smollan_digital_games for update to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "authorized staff delete digital games" on public.smollan_digital_games for delete to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
