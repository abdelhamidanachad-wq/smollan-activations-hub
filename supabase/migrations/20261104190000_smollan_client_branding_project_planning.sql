-- Client and project brand system, configurable activation planning presets.
alter table public.smollan_clients
  add column if not exists logo_url text,
  add column if not exists background_url text,
  add column if not exists brand_color text not null default '#2457A6',
  add column if not exists contact_directory jsonb not null default '{}'::jsonb;
alter table public.smollan_clients
  add constraint smollan_clients_brand_color_hex_check
  check (brand_color ~ '^#[0-9A-Fa-f]{6}$') not valid;
alter table public.smollan_projects
  add column if not exists planning_pattern text not null default 'none',
  add column if not exists planning_custom_days jsonb not null default '[]'::jsonb,
  add column if not exists brand_color text not null default '#2457A6';
alter table public.smollan_projects
  add constraint smollan_projects_planning_pattern_check
  check (planning_pattern in ('VSD','SD','weekdays','daily','custom','none')) not valid;
alter table public.smollan_projects
  add constraint smollan_projects_brand_color_hex_check
  check (brand_color ~ '^#[0-9A-Fa-f]{6}$') not valid;
create index if not exists smollan_projects_planning_pattern_idx
  on public.smollan_projects(planning_pattern,start_date,end_date);
