-- Evaluate auth.uid() once per statement instead of once per row in RLS expressions.
do $$
declare
  r record;
  v_sql text;
  v_roles text;
  v_qual text;
  v_with_check text;
begin
  for r in
    select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (coalesce(qual,'') like '%auth.uid()%'
        or coalesce(with_check,'') like '%auth.uid()%')
  loop
    v_roles := array_to_string(r.roles, ', ');
    v_qual := case when r.qual is null then null
      else replace(r.qual, 'auth.uid()', '(select auth.uid())') end;
    v_with_check := case when r.with_check is null then null
      else replace(r.with_check, 'auth.uid()', '(select auth.uid())') end;

    execute format('drop policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);

    v_sql := format(
      'create policy %I on %I.%I as %s for %s to %s',
      r.policyname, r.schemaname, r.tablename, r.permissive, r.cmd, v_roles
    );
    if v_qual is not null then
      v_sql := v_sql || format(' using (%s)', v_qual);
    end if;
    if v_with_check is not null then
      v_sql := v_sql || format(' with check (%s)', v_with_check);
    end if;
    execute v_sql;
  end loop;
end
$$;
