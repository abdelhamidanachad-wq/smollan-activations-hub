-- Complete project creative setup, multilingual surveys and digital game campaigns.
alter table public.smollan_activation_configs
  add column if not exists brand_logo_url text,
  add column if not exists brand_primary_color text not null default '#245de8',
  add column if not exists brand_secondary_color text not null default '#172f4d',
  add column if not exists brand_background_url text,
  add column if not exists activation_triggers_json jsonb not null default '{}'::jsonb,
  add column if not exists plv_options_json jsonb not null default '[]'::jsonb,
  add column if not exists goodies_options_json jsonb not null default '[]'::jsonb,
  add column if not exists tasting_options_json jsonb not null default '[]'::jsonb,
  add column if not exists promoter_plan_json jsonb not null default '{}'::jsonb,
  add column if not exists digital_game_config_json jsonb not null default '{}'::jsonb,
  add column if not exists survey_config_json jsonb not null default '{}'::jsonb;

create unique index if not exists smollan_activation_configs_project_uidx
  on public.smollan_activation_configs(project_id);

alter table public.smollan_project_forms
  add column if not exists template_key text,
  add column if not exists default_language text not null default 'fr',
  add column if not exists available_languages text[] not null default array['fr','ar','en'],
  add column if not exists translations jsonb not null default '{}'::jsonb;

create table if not exists public.smollan_digital_games (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.smollan_projects(id) on delete cascade,
  title text not null,
  game_type text not null check (game_type in ('spin_wheel','scratch_card','quiz','instant_win','memory')),
  status text not null default 'Draft' check (status in ('Draft','Ready','Published','Paused','Archived')),
  slug text not null unique,
  default_language text not null default 'fr',
  available_languages text[] not null default array['fr','ar','en'],
  translations jsonb not null default '{}'::jsonb,
  prizes jsonb not null default '[]'::jsonb,
  questions jsonb not null default '[]'::jsonb,
  rules jsonb not null default '{}'::jsonb,
  starts_at timestamptz,
  ends_at timestamptz,
  max_plays_per_phone integer not null default 1 check (max_plays_per_phone > 0),
  qr_destination text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists smollan_digital_games_project_idx on public.smollan_digital_games(project_id, created_at desc);
alter table public.smollan_digital_games enable row level security;
grant select, insert, update, delete on public.smollan_digital_games to authenticated;
create policy "active members read digital games" on public.smollan_digital_games for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "authorized staff manage digital games" on public.smollan_digital_games for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')))
with check (created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
