-- One-time bootstrap for the designated, email-verified superadmin.
-- It can only succeed while no active platform administrator exists.
create or replace function public.smollan_bootstrap_first_admin()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user auth.users%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into v_user
  from auth.users
  where id = auth.uid();

  if lower(coalesce(v_user.email, '')) <> 'abdelhamid.anachad@gmail.com' then
    raise exception 'Not authorized for superadmin bootstrap';
  end if;

  if v_user.email_confirmed_at is null then
    raise exception 'Verify the superadmin email before bootstrapping access';
  end if;

  if exists (
    select 1 from public.smollan_memberships
    where role = 'platform_admin' and is_active = true
  ) then
    return false;
  end if;

  insert into public.smollan_memberships(user_id, email, display_name, role, is_active, approved_at)
  values (v_user.id, lower(v_user.email), 'Abdelhamid Anachad', 'platform_admin', true, now())
  on conflict (user_id) do update
    set email = excluded.email,
        display_name = excluded.display_name,
        role = 'platform_admin',
        is_active = true,
        approved_at = now(),
        updated_at = now();

  return true;
end;
$$;

revoke all on function public.smollan_bootstrap_first_admin() from public;
grant execute on function public.smollan_bootstrap_first_admin() to authenticated;
