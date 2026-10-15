-- Extended SMOLLAN operations modules: uniform ledger, assets, WhatsApp directory and HR/PEC metadata.
create table if not exists public.smollan_uniform_skus (
 id uuid primary key default gen_random_uuid(), sku text not null unique, name text not null, size text, color text,
 quantity_on_hand integer not null default 0 check(quantity_on_hand>=0), reorder_level integer not null default 0 check(reorder_level>=0),
 unit_cost numeric(12,2) check(unit_cost is null or unit_cost>=0), status text not null default 'active' check(status in ('active','discontinued')),
 notes text, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.smollan_uniform_transactions (
 id uuid primary key default gen_random_uuid(), sku_id uuid not null references public.smollan_uniform_skus(id),
 promoter_id uuid references public.smollan_promoters(id), project_id uuid references public.smollan_projects(id),
 transaction_type text not null check(transaction_type in ('receipt','issue','return','damage','adjustment')),
 quantity integer not null check(quantity>0), transaction_date date not null default current_date, reference text, notes text,
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.smollan_assets (
 id uuid primary key default gen_random_uuid(), asset_code text not null unique, name text not null, asset_type text not null,
 serial_number text, status text not null default 'available' check(status in ('available','assigned','maintenance','retired','lost')),
 project_id uuid references public.smollan_projects(id), store_id uuid references public.smollan_stores(id),
 promoter_id uuid references public.smollan_promoters(id), assigned_to text, purchase_date date,
 purchase_cost numeric(12,2) check(purchase_cost is null or purchase_cost>=0), drive_url text, notes text,
 created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.smollan_whatsapp_groups (
 id uuid primary key default gen_random_uuid(), name text not null, group_type text not null default 'project' check(group_type in ('project','client','city','supervisor','internal')),
 project_id uuid references public.smollan_projects(id), client_name text, city text, supervisor_id uuid references public.smollan_supervisors(id),
 group_url text, owner_name text, status text not null default 'active' check(status in ('active','archived')), notes text,
 created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.smollan_pec_records (
 id uuid primary key default gen_random_uuid(), promoter_id uuid not null references public.smollan_promoters(id) on delete cascade,
 project_id uuid references public.smollan_projects(id), pec_status text not null default 'pending' check(pec_status in ('pending','requested','approved','signed','expired','rejected')),
 start_date date, end_date date, private_document_ref text, notes text, created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(end_date is null or start_date is null or end_date>=start_date)
);
create table if not exists public.smollan_promoter_documents (
 id uuid primary key default gen_random_uuid(), promoter_id uuid not null references public.smollan_promoters(id) on delete cascade,
 document_type text not null check(document_type in ('cin_front','cin_back','rib','bank_document','contract','pec','device_policy','other')),
 storage_path text not null, display_name text not null, issue_date date, expiry_date date,
 status text not null default 'active' check(status in ('active','expired','pending_review','rejected')), notes text,
 uploaded_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create index if not exists smollan_uniform_transactions_sku_date_idx on public.smollan_uniform_transactions(sku_id,transaction_date desc);
create index if not exists smollan_assets_project_status_idx on public.smollan_assets(project_id,status);
create index if not exists smollan_whatsapp_groups_project_idx on public.smollan_whatsapp_groups(project_id,status);
create index if not exists smollan_pec_records_promoter_idx on public.smollan_pec_records(promoter_id,end_date);
create index if not exists smollan_promoter_documents_promoter_idx on public.smollan_promoter_documents(promoter_id,document_type);
create or replace function public.smollan_apply_uniform_movement() returns trigger language plpgsql set search_path=public as $$
declare current_qty integer; delta integer;
begin
 select quantity_on_hand into current_qty from public.smollan_uniform_skus where id=new.sku_id for update;
 if current_qty is null then raise exception 'Uniform SKU not found'; end if;
 if new.transaction_type in ('receipt','return','adjustment') then delta:=new.quantity; else delta:=-new.quantity; end if;
 if current_qty+delta<0 then raise exception 'Insufficient uniform stock: % available, % requested',current_qty,new.quantity; end if;
 update public.smollan_uniform_skus set quantity_on_hand=current_qty+delta,updated_at=now() where id=new.sku_id;
 return new;
end $$;
drop trigger if exists smollan_uniform_movement_stock on public.smollan_uniform_transactions;
create trigger smollan_uniform_movement_stock before insert on public.smollan_uniform_transactions for each row execute function public.smollan_apply_uniform_movement();
alter table public.smollan_uniform_skus enable row level security;
alter table public.smollan_uniform_transactions enable row level security;
alter table public.smollan_assets enable row level security;
alter table public.smollan_whatsapp_groups enable row level security;
alter table public.smollan_pec_records enable row level security;
alter table public.smollan_promoter_documents enable row level security;
grant select,insert,update on public.smollan_uniform_skus,public.smollan_uniform_transactions,public.smollan_assets,public.smollan_whatsapp_groups,public.smollan_pec_records,public.smollan_promoter_documents to authenticated;
create policy "active members read uniform stock" on public.smollan_uniform_skus for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "operations manage uniform stock" on public.smollan_uniform_skus for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator','procurement_production'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator','procurement_production')));
create policy "active members read uniform movements" on public.smollan_uniform_transactions for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "operations record uniform movements" on public.smollan_uniform_transactions for insert to authenticated with check(created_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator','procurement_production')));
create policy "active members read assets" on public.smollan_assets for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "operations manage assets" on public.smollan_assets for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','procurement_production','merchandising')));
create policy "active members read WhatsApp directory" on public.smollan_whatsapp_groups for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active));
create policy "coordinators manage WhatsApp directory" on public.smollan_whatsapp_groups for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));
create policy "HR authorized PEC records" on public.smollan_pec_records for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','hr_coordinator','finance','supervisor')) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "HR manages PEC records" on public.smollan_pec_records for all to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','hr_coordinator')));
create policy "HR restricted promoter documents" on public.smollan_promoter_documents for select to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator','finance')) or exists(select 1 from public.smollan_promoters p where p.id=promoter_id and p.user_id=auth.uid()));
create policy "HR uploads promoter documents" on public.smollan_promoter_documents for insert to authenticated with check(uploaded_by=auth.uid() and exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator')));
create policy "HR updates promoter documents" on public.smollan_promoter_documents for update to authenticated using(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator'))) with check(exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','hr_coordinator')));
