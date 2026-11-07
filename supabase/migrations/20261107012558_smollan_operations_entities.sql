-- Applied to the dedicated SMOLLAN project on 2026-10-15.
-- Identity and bank records are isolated in smollan_promoter_private_details.
create table public.smollan_supervisors (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id),
 full_name text not null, email text, phone text, city text, zone text,
 status text not null default 'Active' check(status in ('Active','Inactive','On Leave')),
 notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index smollan_supervisors_email_uidx on public.smollan_supervisors(lower(email)) where email is not null;
create table public.smollan_stores (
 id uuid primary key default gen_random_uuid(), source_code text not null unique, name text not null,
 city text, banner text, format text, address text, status text not null default 'Active' check(status in ('Active','Inactive')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_promoters (
 id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id), source_cin text unique,
 full_name text not null, phone text, email text, city text,
 contract_type text not null default 'Permanent' check(contract_type in ('Permanent','Activation','Freelance')),
 uniform_size text, device_type text, device_model text, mdm_identifier text,
 status text not null default 'Available' check(status in ('Available','Assigned','On Leave','Inactive')),
 rating numeric(3,2) check(rating is null or rating between 0 and 5), notes text, documents_folder_ref text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_promoter_private_details (
 promoter_id uuid primary key references public.smollan_promoters(id) on delete cascade,
 national_id_ciphertext text, bank_details_ciphertext text, bank_document_ref text,
 cin_document_refs jsonb not null default '[]'::jsonb, pec_document_ref text, pec_start_date date, pec_end_date date,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_project_stores (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id) on delete cascade,
 store_id uuid not null references public.smollan_stores(id), supervisor_id uuid references public.smollan_supervisors(id),
 expected_promoters integer not null default 0 check(expected_promoters>=0), created_at timestamptz not null default now(),
 unique(project_id,store_id)
);
create table public.smollan_project_supervisors (
 project_id uuid not null references public.smollan_projects(id) on delete cascade,
 supervisor_id uuid not null references public.smollan_supervisors(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(project_id,supervisor_id)
);
create table public.smollan_assignments (
 id uuid primary key default gen_random_uuid(), source_id text unique, promoter_id uuid not null references public.smollan_promoters(id),
 project_id uuid not null references public.smollan_projects(id) on delete cascade, store_id uuid not null references public.smollan_stores(id),
 supervisor_id uuid references public.smollan_supervisors(id), start_date date not null, end_date date,
 status text not null default 'Active' check(status in ('Active','Completed','Cancelled')), created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(end_date is null or end_date>=start_date)
);
create unique index smollan_assignments_no_exact_active_duplicate on public.smollan_assignments(promoter_id,project_id,store_id) where status='Active';
create index smollan_assignments_promoter_status_idx on public.smollan_assignments(promoter_id,status);
create table public.smollan_attendance (
 id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.smollan_assignments(id) on delete cascade,
 promoter_id uuid not null references public.smollan_promoters(id), project_id uuid not null references public.smollan_projects(id),
 store_id uuid not null references public.smollan_stores(id), attendance_date date not null,
 status text not null check(status in ('Present','Absent','Late','Half-Day','Replaced')), check_in timestamptz, check_out timestamptz,
 source text not null default 'Manual' check(source in ('SMART','Supervisor App','Manual','Portal')),
 photo_ref text, validation_status text not null default 'Pending' check(validation_status in ('Pending','Validated','Rejected')),
 validated_by uuid references auth.users(id), validated_at timestamptz, notes text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), unique(assignment_id,attendance_date), check(check_out is null or check_in is null or check_out>=check_in)
);
create table public.smollan_resource_requests (
 id uuid primary key default gen_random_uuid(), source_id text unique,
 request_type text not null check(request_type in ('PEC','IT Policy / MDM','Uniform','Tablet')),
 promoter_id uuid not null references public.smollan_promoters(id), project_id uuid not null references public.smollan_projects(id),
 store_id uuid not null references public.smollan_stores(id), requester_user_id uuid references auth.users(id),
 status text not null default 'Pending' check(status in ('Pending','Approved','Rejected','Fulfilled')), notes text, decision_reason text,
 decided_by uuid references auth.users(id), decided_at timestamptz, fulfilled_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_gifts (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id) on delete cascade,
 name text not null, category text, source text, total_quantity integer not null default 0 check(total_quantity>=0),
 unit_value numeric(14,2) not null default 0 check(unit_value>=0), status text not null default 'Planning', description text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_gift_dispatches (
 id uuid primary key default gen_random_uuid(), gift_id uuid not null references public.smollan_gifts(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id), store_id uuid not null references public.smollan_stores(id),
 allocated_quantity integer not null check(allocated_quantity>=0), distributed_quantity integer not null default 0 check(distributed_quantity>=0),
 dispatch_status text not null default 'Planned' check(dispatch_status in ('Planned','Dispatched','Received','Cancelled')),
 dispatch_date date, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(distributed_quantity<=allocated_quantity)
);
create table public.smollan_gift_distributions (
 id uuid primary key default gen_random_uuid(), gift_id uuid not null references public.smollan_gifts(id),
 project_id uuid not null references public.smollan_projects(id), store_id uuid not null references public.smollan_stores(id),
 promoter_id uuid references public.smollan_promoters(id), quantity integer not null check(quantity>0),
 distributed_at timestamptz not null default now(), receipt_photo_ref text,
 validation_status text not null default 'Pending' check(validation_status in ('Pending','Validated','Rejected')),
 notes text, created_by uuid references auth.users(id)
);
create table public.smollan_plv_materials (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id) on delete cascade,
 name text not null, material_type text not null, production_source text, total_quantity integer not null default 0 check(total_quantity>=0),
 unit_cost numeric(14,2) not null default 0 check(unit_cost>=0), production_status text not null default 'Planning',
 production_deadline date, status text not null default 'Planning', description text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_plv_store_records (
 id uuid primary key default gen_random_uuid(), material_id uuid not null references public.smollan_plv_materials(id) on delete cascade,
 project_id uuid not null references public.smollan_projects(id), store_id uuid not null references public.smollan_stores(id),
 quantity integer not null default 0 check(quantity>=0), dispatch_status text not null default 'Planned', dispatch_date date,
 installation_status text not null default 'Not installed', installation_deadline date, installation_date date,
 uninstallation_deadline date, uninstallation_date date, installer_id uuid references public.smollan_supervisors(id),
 installation_photo_ref text, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_project_budgets (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id) on delete cascade,
 category text not null, budget_amount numeric(14,2) not null default 0 check(budget_amount>=0),
 actual_amount numeric(14,2) not null default 0 check(actual_amount>=0), funding_source text, budget_date date,
 status text not null default 'Draft', notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_quotations (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id),
 client_id uuid references public.smollan_clients(id), quotation_number text unique, quotation_date date not null default current_date,
 status text not null default 'Draft' check(status in ('Draft','Submitted','Approved','Rejected','Expired')),
 total_amount numeric(14,2) not null default 0 check(total_amount>=0), currency char(3) not null default 'MAD',
 notes text, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_quotation_lines (
 id uuid primary key default gen_random_uuid(), quotation_id uuid not null references public.smollan_quotations(id) on delete cascade,
 description text not null, quantity numeric(12,2) not null check(quantity>0), unit_price numeric(14,2) not null check(unit_price>=0),
 line_total numeric(14,2) generated always as (quantity*unit_price) stored
);
create table public.smollan_expenses (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.smollan_projects(id),
 category text not null, amount numeric(14,2) not null check(amount>=0),
 spend_type text not null check(spend_type in ('Planned','Additional')), justification text,
 expense_date date not null default current_date, receipt_ref text,
 approval_status text not null default 'Pending' check(approval_status in ('Pending','Approved','Rejected')),
 payment_status text not null default 'Unpaid' check(payment_status in ('Unpaid','Partially Paid','Paid')),
 notes text, submitted_by uuid references auth.users(id), reviewed_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.smollan_import_batches (
 id uuid primary key default gen_random_uuid(), filename text not null, worksheet_name text, target_entity text not null,
 import_mode text not null check(import_mode in ('create_only','update_matched','create_and_update')),
 status text not null default 'Preview' check(status in ('Preview','Validated','Running','Completed','Failed','Cancelled')),
 total_rows integer not null default 0, created_rows integer not null default 0, updated_rows integer not null default 0,
 skipped_rows integer not null default 0, error_rows integer not null default 0, source_file_ref text,
 created_by uuid references auth.users(id), confirmed_at timestamptz, created_at timestamptz not null default now()
);
create table public.smollan_import_row_results (
 id bigint generated always as identity primary key, batch_id uuid not null references public.smollan_import_batches(id) on delete cascade,
 source_row_number integer not null, source_identifiers jsonb not null default '{}'::jsonb,
 mapped_data jsonb not null default '{}'::jsonb,
 result_status text not null check(result_status in ('Ready','Created','Updated','Skipped','Error','Ambiguous')),
 message text, target_record_id uuid, created_at timestamptz not null default now(), unique(batch_id,source_row_number)
);

-- RLS is on every new table; no anonymous access. Membership is admin-managed.
do $$ declare t text; begin
 foreach t in array array['smollan_supervisors','smollan_stores','smollan_promoters','smollan_promoter_private_details','smollan_project_stores','smollan_project_supervisors','smollan_assignments','smollan_attendance','smollan_resource_requests','smollan_gifts','smollan_gift_dispatches','smollan_gift_distributions','smollan_plv_materials','smollan_plv_store_records','smollan_project_budgets','smollan_quotations','smollan_quotation_lines','smollan_expenses','smollan_import_batches','smollan_import_row_results'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
revoke all on public.smollan_supervisors,public.smollan_stores,public.smollan_promoters,public.smollan_promoter_private_details,public.smollan_project_stores,public.smollan_project_supervisors,public.smollan_assignments,public.smollan_attendance,public.smollan_resource_requests,public.smollan_gifts,public.smollan_gift_dispatches,public.smollan_gift_distributions,public.smollan_plv_materials,public.smollan_plv_store_records,public.smollan_project_budgets,public.smollan_quotations,public.smollan_quotation_lines,public.smollan_expenses,public.smollan_import_batches,public.smollan_import_row_results from anon,authenticated;
grant select on public.smollan_supervisors,public.smollan_stores,public.smollan_promoters,public.smollan_project_stores,public.smollan_project_supervisors,public.smollan_assignments,public.smollan_attendance,public.smollan_resource_requests,public.smollan_gifts,public.smollan_gift_dispatches,public.smollan_gift_distributions,public.smollan_plv_materials,public.smollan_plv_store_records,public.smollan_project_budgets,public.smollan_quotations,public.smollan_quotation_lines,public.smollan_expenses,public.smollan_import_batches,public.smollan_import_row_results to authenticated;
grant select on public.smollan_promoter_private_details to authenticated;
grant insert,update on public.smollan_supervisors,public.smollan_stores,public.smollan_promoters,public.smollan_project_stores,public.smollan_project_supervisors,public.smollan_assignments,public.smollan_attendance,public.smollan_resource_requests,public.smollan_gifts,public.smollan_gift_dispatches,public.smollan_gift_distributions,public.smollan_plv_materials,public.smollan_plv_store_records,public.smollan_project_budgets,public.smollan_quotations,public.smollan_quotation_lines,public.smollan_expenses,public.smollan_import_batches,public.smollan_import_row_results to authenticated;
grant insert,update on public.smollan_promoter_private_details to authenticated;
create policy "active members read supervisors" on public.smollan_supervisors for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage supervisors" on public.smollan_supervisors for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator')));
create policy "active members read stores" on public.smollan_stores for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "operations manage stores" on public.smollan_stores for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor')));
create policy "authorized staff read promoters" on public.smollan_promoters for select to authenticated using(user_id=auth.uid() or exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role <> 'promoter'));
create policy "hr manage promoters" on public.smollan_promoters for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator')));
create policy "sensitive promoter details staff" on public.smollan_promoter_private_details for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator','finance')) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "hr manage sensitive promoter details" on public.smollan_promoter_private_details for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','hr_coordinator')));
create policy "active members read project store links" on public.smollan_project_stores for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage project store links" on public.smollan_project_stores for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager')));
create policy "active members read project supervisor links" on public.smollan_project_supervisors for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage project supervisor links" on public.smollan_project_supervisors for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager')));
create policy "active members read assignments" on public.smollan_assignments for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "operations manage assignments" on public.smollan_assignments for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor','hr_coordinator')));
create policy "authorized attendance read" on public.smollan_attendance for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "promoters or supervisors create attendance" on public.smollan_attendance for insert to authenticated with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor','hr_coordinator')) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "staff validate attendance" on public.smollan_attendance for update to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor','hr_coordinator')));
create policy "authorized request read" on public.smollan_resource_requests for select to authenticated using(requester_user_id=auth.uid() or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()) or exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "supervisors submit requests" on public.smollan_resource_requests for insert to authenticated with check(requester_user_id=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','supervisor','hr_coordinator')));
create policy "coordinators decide requests" on public.smollan_resource_requests for update to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_manager','hr_coordinator')));
do $$ declare t text; begin
 foreach t in array array['smollan_gifts','smollan_gift_dispatches','smollan_gift_distributions','smollan_plv_materials','smollan_plv_store_records'] loop
 execute format('create policy %I on public.%I for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active))','active members read '||t,t);
 execute format('create policy %I on public.%I for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''activation_coordinator'',''field_manager'',''supervisor'',''procurement_production''))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''activation_coordinator'',''field_manager'',''supervisor'',''procurement_production'')))','operations manage '||t,t);
 end loop;
 foreach t in array array['smollan_project_budgets','smollan_quotations','smollan_quotation_lines','smollan_expenses'] loop
 execute format('create policy %I on public.%I for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''activation_coordinator'',''finance'')))','finance read '||t,t);
 execute format('create policy %I on public.%I for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''finance''))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''finance'')))','finance manage '||t,t);
 end loop;
 foreach t in array array['smollan_import_batches','smollan_import_row_results'] loop
 execute format('create policy %I on public.%I for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''leadership'',''activation_coordinator'',''field_manager'',''hr_coordinator'')))','authorized read '||t,t);
 execute format('create policy %I on public.%I for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''activation_coordinator''))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in (''platform_admin'',''activation_coordinator'')))','authorized manage '||t,t);
 end loop;
end $$;
create index smollan_audit_actor_created_idx on public.smollan_audit_events(actor_id,created_at desc);
create index smollan_clients_account_owner_idx on public.smollan_clients(account_owner);
create index smollan_clients_created_by_idx on public.smollan_clients(created_by);
create index smollan_memberships_approved_by_idx on public.smollan_memberships(approved_by);
create index smollan_projects_owner_idx on public.smollan_projects(owner_id);
create index smollan_projects_created_by_idx on public.smollan_projects(created_by);
create index smollan_tasks_created_by_idx on public.smollan_tasks(created_by);
