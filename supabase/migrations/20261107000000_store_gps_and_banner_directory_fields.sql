alter table public.smollan_stores
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists gps_status text not null default 'unverified',
  add column if not exists gps_source text,
  add column if not exists coordinate_updated_at timestamptz;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'smollan_stores_latitude_range') then
    alter table public.smollan_stores add constraint smollan_stores_latitude_range check (latitude is null or latitude between -90 and 90);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'smollan_stores_longitude_range') then
    alter table public.smollan_stores add constraint smollan_stores_longitude_range check (longitude is null or longitude between -180 and 180);
  end if;
end $$;

create index if not exists smollan_stores_banner_city_idx on public.smollan_stores (banner, city);
create index if not exists smollan_stores_gps_status_idx on public.smollan_stores (gps_status);
