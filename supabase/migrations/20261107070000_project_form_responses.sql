-- Store responses to the multilingual project-form builder separately from legacy survey templates.
create table if not exists public.smollan_project_form_responses (
 id uuid primary key default gen_random_uuid(),
 form_id uuid not null references public.smollan_project_forms(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 promoter_id uuid references public.smollan_promoters(id),
 assignment_id uuid references public.smollan_assignments(id),
 store_id uuid references public.smollan_stores(id),
 answers jsonb not null default '{}'::jsonb,
 submitted_at timestamptz not null default now(),
 submitted_by uuid not null references auth.users(id),
 review_status text not null default 'Pending' check(review_status in ('Pending','Reviewed','Rejected')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 reviewer_notes text
);
create index if not exists smollan_project_form_responses_project_idx on public.smollan_project_form_responses(project_id,submitted_at desc);
create index if not exists smollan_project_form_responses_form_idx on public.smollan_project_form_responses(form_id,submitted_at desc);
alter table public.smollan_project_form_responses enable row level security;
grant select,insert,update on public.smollan_project_form_responses to authenticated;

create policy "project form responses staff read" on public.smollan_project_form_responses for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "promoters read own project form responses" on public.smollan_project_form_responses for select to authenticated
using (submitted_by=auth.uid());
create policy "assigned promoters submit project form responses" on public.smollan_project_form_responses for insert to authenticated
with check (
 submitted_by=auth.uid()
 and promoter_id in (select p.id from public.smollan_promoters p where p.user_id=auth.uid())
 and exists(select 1 from public.smollan_assignments a where a.promoter_id=promoter_id and a.project_id=project_id and a.status='Active')
);
create policy "authorized staff review project form responses" on public.smollan_project_form_responses for update to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')))
with check (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
