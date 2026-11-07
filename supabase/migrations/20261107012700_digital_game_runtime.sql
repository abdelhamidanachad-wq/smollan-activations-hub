-- Public QR game runtime with server-side prize allocation and one play per browser token.
create table if not exists public.smollan_digital_game_entries (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.smollan_digital_games(id) on delete cascade,
 participant_fingerprint text not null,
 participant_phone text,
 answers jsonb not null default '{}'::jsonb,
 prize_won text,
 consent boolean not null default false,
 created_at timestamptz not null default now(),
 unique(game_id, participant_fingerprint)
);
alter table public.smollan_digital_game_entries enable row level security;
grant select on public.smollan_digital_game_entries to authenticated;
create policy "staff read digital game entries" on public.smollan_digital_game_entries for select to authenticated
using (exists(select 1 from public.smollan_memberships m where m.user_id=auth.uid() and m.is_active and m.role in ('platform_admin','leadership','activation_coordinator','field_operations','supervisor')));

create or replace function public.smollan_get_digital_game(p_slug text)
returns jsonb language plpgsql security invoker set search_path=public as $$
declare v jsonb;
begin
 select jsonb_build_object('id',id,'title',title,'game_type',game_type,'default_language',default_language,
 'available_languages',available_languages,'translations',translations,'questions',questions,'rules',rules)
 into v from public.smollan_digital_games where slug=p_slug and status='Published'
 and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now());
 return v;
end $$;
revoke all on function public.smollan_get_digital_game(text) from public;
grant execute on function public.smollan_get_digital_game(text) to anon, authenticated;
grant select (id,title,game_type,slug,default_language,available_languages,translations,questions,rules,status,starts_at,ends_at) on public.smollan_digital_games to anon;
create policy "published games public read" on public.smollan_digital_games for select to anon, authenticated using (status='Published' and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now()));

create or replace function public.smollan_play_digital_game(
 p_slug text,p_fingerprint text,p_phone text default null,p_answers jsonb default '{}'::jsonb,p_consent boolean default false
) returns jsonb language plpgsql security invoker set search_path=public as $$
declare
 g public.smollan_digital_games%rowtype;
 chosen jsonb;
 chosen_idx bigint;
 total_weight numeric;
 prize_name text;
 updated_prizes jsonb;
 existing_id uuid;
begin
 if coalesce(length(trim(p_fingerprint)),0)<16 then raise exception 'Invalid play token'; end if;
 select * into g from public.smollan_digital_games where slug=p_slug and status='Published'
 and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now()) for update;
 if not found then raise exception 'This game is not currently available'; end if;
 if coalesce((g.rules->>'require_phone')::boolean,false) and coalesce(trim(p_phone),'')='' then raise exception 'A mobile number is required'; end if;
 if coalesce((g.rules->>'consent_text')::text,'')<>'' and not coalesce(p_consent,false) then raise exception 'Consent is required to play'; end if;
 select id into existing_id from public.smollan_digital_game_entries where game_id=g.id and participant_fingerprint=p_fingerprint;
 if existing_id is not null then raise exception 'This device has already played'; end if;
 if g.game_type='quiz' and jsonb_array_length(g.questions)=0 then raise exception 'This quiz has no questions configured'; end if;
 if coalesce(trim(p_phone),'')<>'' and (select count(*) from public.smollan_digital_game_entries where game_id=g.id and participant_phone=trim(p_phone))>=g.max_plays_per_phone then
   raise exception 'The play limit for this mobile number has been reached';
 end if;
 select sum(greatest(0,coalesce((e.value->>'weight')::numeric,1))) into total_weight
 from jsonb_array_elements(g.prizes) e(value) where coalesce((e.value->>'quantity')::integer,0)>0;
 if g.game_type='quiz' and exists(select 1 from jsonb_array_elements(g.questions) with ordinality x(elem,ord) where coalesce(p_answers->>(x.ord-1)::text,'')<>coalesce(x.elem->>'correct_answer','')) then
  prize_name:='Thank you for playing';
 elsif coalesce(total_weight,0)>0 then
  select idx,elem into chosen_idx,chosen from (
   select ordinality idx,elem,
    sum(greatest(0,coalesce((elem->>'weight')::numeric,1))) over(order by ordinality) cumulative,
    sum(greatest(0,coalesce((elem->>'weight')::numeric,1))) over() total
   from jsonb_array_elements(g.prizes) with ordinality x(elem,ordinality)
   where coalesce((elem->>'quantity')::integer,0)>0
  ) weighted where cumulative>=random()*total order by idx limit 1;
  prize_name:=coalesce(chosen->>'name','Thank you');
  select jsonb_agg(case when ordinality=chosen_idx then jsonb_set(elem,'{quantity}',to_jsonb(greatest(0,(elem->>'quantity')::integer-1)),false) else elem end order by ordinality)
  into updated_prizes from jsonb_array_elements(g.prizes) with ordinality x(elem,ordinality);
  update public.smollan_digital_games set prizes=coalesce(updated_prizes,'[]'::jsonb),updated_at=now() where id=g.id;
 else
  prize_name:='Thank you for participating';
 end if;
 insert into public.smollan_digital_game_entries(game_id,participant_fingerprint,participant_phone,answers,prize_won,consent)
 values(g.id,p_fingerprint,nullif(trim(p_phone),''),coalesce(p_answers,'{}'::jsonb),prize_name,coalesce(p_consent,false));
 return jsonb_build_object('success',true,'prize',prize_name);
end $$;
revoke all on function public.smollan_play_digital_game(text,text,text,jsonb,boolean) from public, anon, authenticated;
grant execute on function public.smollan_play_digital_game(text,text,text,jsonb,boolean) to service_role;
