-- Private HR document storage and Drive resource index.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('smollan-hr-private','smollan-hr-private',false,10485760,array['image/jpeg','image/png','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','application/pdf'];
create table if not exists public.smollan_drive_resources(
 id uuid primary key default gen_random_uuid(), name text not null, resource_type text not null default 'folder' check(resource_type in ('folder','brief','artwork','report','photo','quotation','invoice','other')),
 project_id uuid references public.smollan_projects(id), store_id uuid references public.smollan_stores(id), promoter_id uuid references public.smollan_promoters(id),
 drive_url text not null, owner_name text, access_scope text not null default 'team' check(access_scope in ('team','operations','finance','hr')),
 status text not null default 'active' check(status in ('active','archived')), notes text, created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists smollan_drive_resources_project_idx on public.smollan_drive_resources(project_id,status);
alter table public.smollan_drive_resources enable row level security;
grant select,insert,update on public.smollan_drive_resources to authenticated;
create policy "authorized members read drive resource index" on public.smollan_drive_resources for select to authenticated using(
 exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and
 (access_scope='team' or access_scope='operations' and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising') or access_scope='finance' and m.role in ('platform_admin','leadership','finance') or access_scope='hr' and m.role in ('platform_admin','leadership','hr_coordinator')))
);
create policy "authorized members manage drive resource index" on public.smollan_drive_resources for all to authenticated using(
 exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','finance','procurement_production','merchandising','hr_coordinator'))
) with check(
 exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','finance','procurement_production','merchandising','hr_coordinator'))
);
create policy "HR and promoter can read private HR objects" on storage.objects for select to authenticated using(
 bucket_id='smollan-hr-private' and (
 exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator','finance')) or
 exists(select 1 from public.smollan_promoters p where p.user_id=auth.uid() and p.id::text=(storage.foldername(name))[1])
 )
);
create policy "HR can upload private HR objects" on storage.objects for insert to authenticated with check(
 bucket_id='smollan-hr-private' and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator'))
);
create policy "HR can update private HR objects" on storage.objects for update to authenticated using(
 bucket_id='smollan-hr-private' and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator'))
) with check(bucket_id='smollan-hr-private' and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator')));
create policy "HR can delete private HR objects" on storage.objects for delete to authenticated using(
 bucket_id='smollan-hr-private' and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator'))
);
