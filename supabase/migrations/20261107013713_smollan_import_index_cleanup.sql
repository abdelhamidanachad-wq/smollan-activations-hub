-- Remove duplicate indexes where the base schema already provides unique constraints.
drop index if exists public.smollan_projects_code_uidx;
drop index if exists public.smollan_stores_source_code_uidx;
