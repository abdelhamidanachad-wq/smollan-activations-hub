-- Normalize historical mappings to one primary supervisor per store.
with ranked_supervisors as (
  select store_id, supervisor_id,
         row_number() over (partition by store_id order by count(*) desc, supervisor_id) as rn
  from public.smollan_project_stores
  where supervisor_id is not null
  group by store_id, supervisor_id
)
update public.smollan_store_supervisors ss
set is_primary = (ranked.rn = 1)
from ranked_supervisors ranked
where ranked.store_id = ss.store_id and ranked.supervisor_id = ss.supervisor_id;

create unique index if not exists smollan_store_supervisors_one_primary_idx
  on public.smollan_store_supervisors(store_id) where is_primary;
