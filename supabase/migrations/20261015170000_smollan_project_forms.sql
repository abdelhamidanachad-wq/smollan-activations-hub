-- Project forms and survey responses for secure promoter self-service.
create table if not exists public.smollan_project_forms (
 id uuid primary key default gen_random_uuid(),
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 title text not null check (char_length(trim(title)) between 2 and 180),
 slug text not null unique,
 form_type text not null check (form_type in ('attendance','survey')),
 questions jsonb not null default '[]'::jsonb,
 is_active boolean not null default true,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists smollan_project_forms_project_idx on public.smollan_project_forms(project_id, form_type, is_active);
create table if not exists public.smollan_survey_responses (
 id uuid primary key default gen_random_uuid(),
 form_id uuid not null references public.smollan_project_forms(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 promoter_id uuid not null references public.smollan_promoters(id) on delete cascade,
 answers jsonb not null default '{}'::jsonb,
 submitted_by uuid not null references auth.users(id),
 submitted_at timestamptz not null default now()
);
create index if not exists smollan_survey_responses_project_idx on public.smollan_survey_responses(project_id, submitted_at desc);
alter table public.smollan_project_forms enable row level security;
alter table public.smollan_survey_responses enable row level security;
grant select, insert, update on public.smollan_project_forms to authenticated;
grant select, insert on public.smollan_survey_responses to authenticated;
create policy "active members read project forms" on public.smollan_project_forms for select to authenticated
using (is_active and (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active) or exists(select 1 from public.smollan_promoters p where p.user_id=auth.uid())));
create policy "coordinators manage project forms" on public.smollan_project_forms for all to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')))
with check (created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "promoters submit survey responses for own assignments" on public.smollan_survey_responses for insert to authenticated
with check (
 submitted_by=auth.uid()
 and exists(select 1 from public.smollan_promoters p where p.id=smollan_survey_responses.promoter_id and p.user_id=auth.uid())
 and exists(select 1 from public.smollan_assignments a where a.promoter_id=smollan_survey_responses.promoter_id and a.project_id=smollan_survey_responses.project_id and a.status='Active')
 and exists(select 1 from public.smollan_project_forms f where f.id=smollan_survey_responses.form_id and f.project_id=smollan_survey_responses.project_id and f.form_type='survey' and f.is_active)
);
create policy "promoters and staff read survey responses" on public.smollan_survey_responses for select to authenticated
using (
 exists(select 1 from public.smollan_promoters p where p.id=smollan_survey_responses.promoter_id and p.user_id=auth.uid())
 or exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor'))
);

-- Tighten promoter attendance writes to the promoter's own active assignment.
drop policy if exists "promoters or supervisors create attendance" on public.smollan_attendance;
create policy "promoters or supervisors create attendance" on public.smollan_attendance for insert to authenticated
with check (
  (
    exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','hr_coordinator'))
    and exists(select 1 from public.smollan_assignments a where a.id=smollan_attendance.assignment_id and a.promoter_id=smollan_attendance.promoter_id and a.project_id=smollan_attendance.project_id and a.store_id=smollan_attendance.store_id)
  )
  or
  (
    exists(select 1 from public.smollan_promoters p where p.id=smollan_attendance.promoter_id and p.user_id=auth.uid())
    and exists(select 1 from public.smollan_assignments a where a.id=smollan_attendance.assignment_id and a.promoter_id=smollan_attendance.promoter_id and a.project_id=smollan_attendance.project_id and a.store_id=smollan_attendance.store_id and a.status='Active')
  )
);
