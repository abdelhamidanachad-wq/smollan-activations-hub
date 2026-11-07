-- Add indexes to FK columns that are not already covered by a leading index key.
-- This avoids sequential scans on joins and parent deletes/updates as the operations tables grow.
do $$
declare
  r record;
  v_index_name text;
begin
  for r in
    select
      c.oid as constraint_oid,
      c.conrelid,
      c.conkey,
      string_agg(format('%I', a.attname), ', ' order by k.ordinality) as column_list
    from pg_constraint c
    cross join lateral unnest(c.conkey) with ordinality as k(attnum, ordinality)
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
    join pg_namespace n on n.oid = c.connamespace
    where c.contype = 'f'
      and n.nspname = 'public'
    group by c.oid, c.conrelid, c.conkey
  loop
    if not exists (
      select 1
      from pg_index i
      where i.indrelid = r.conrelid
        and i.indisvalid
        and i.indisready
        and i.indpred is null
        and i.indexprs is null
        and (
          select array_agg(k.attnum order by k.ordinality)
          from unnest(i.indkey::smallint[]) with ordinality as k(attnum, ordinality)
          where k.ordinality <= array_length(r.conkey, 1)
        ) = r.conkey
    ) then
      v_index_name := format('smollan_fk_%s_%s', r.conrelid::oid, r.constraint_oid);
      execute format(
        'create index if not exists %I on %s (%s)',
        v_index_name,
        r.conrelid::regclass,
        r.column_list
      );
    end if;
  end loop;
end
$$;
