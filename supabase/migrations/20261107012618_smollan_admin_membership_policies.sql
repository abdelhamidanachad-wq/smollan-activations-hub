-- Secure membership administration for the SMOLLAN app settings page.
-- Never store account passwords in application tables or source control.
create or replace function public.smollan_is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.smollan_memberships m
    where m.user_id = auth.uid()
      and m.is_active = true
      and m.role = 'platform_admin'
  );
$$;

revoke all on function public.smollan_is_platform_admin() from public;
grant execute on function public.smollan_is_platform_admin() to authenticated;

alter table public.smollan_memberships enable row level security;

drop policy if exists "platform admins read all memberships" on public.smollan_memberships;
create policy "platform admins read all memberships"
  on public.smollan_memberships
  for select to authenticated
  using (public.smollan_is_platform_admin());

drop policy if exists "platform admins update memberships" on public.smollan_memberships;
create policy "platform admins update memberships"
  on public.smollan_memberships
  for update to authenticated
  using (public.smollan_is_platform_admin())
  with check (public.smollan_is_platform_admin());

alter table public.smollan_memberships
  drop constraint if exists smollan_memberships_email_check;

alter table public.smollan_memberships
  add constraint smollan_memberships_email_check
  check (
    lower(email) like '%@smollan.com'
    or lower(email) = 'abdelhamid.anachad@gmail.com'
  );
