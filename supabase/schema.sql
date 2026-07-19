-- Owner-scoped, pseudonymous screening storage. No audio is stored.
create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, anganwadi_id text, district_code text,
  metadata_verified boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.children (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id),
  pseudonym text not null, birth_month date, birth_date date, gestational_weeks int,
  anganwadi_id text, district_code text, created_at timestamptz not null default now(),
  unique(owner_id, id)
);
create table public.consents (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id),
  child_id uuid not null references public.children(id), version text not null,
  granted_at timestamptz not null default now(), withdrawn_at timestamptz
);
create table public.questionnaire_runs (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id),
  child_id uuid not null references public.children(id), engine_version text not null,
  age_months int not null check(age_months between 12 and 36), state text not null,
  answers jsonb not null default '{}'::jsonb,
  analysis jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table public.screening_sessions (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id),
  child_id uuid not null references public.children(id), questionnaire_run_id uuid references public.questionnaire_runs(id),
  consent_id uuid not null references public.consents(id), mode text not null check(mode in ('live','demo')),
  analysis_status text not null, risk_level text, quality_reasons jsonb not null default '[]'::jsonb,
  vttl_ms double precision, cvr_ratio double precision, pfv_std double precision,
  voiced_seconds double precision, child_voiced_seconds double precision, transition_count int,
  audio_source text, model_version text,
  questionnaire_analysis jsonb not null default '{}'::jsonb,
  decision_trace jsonb not null default '[]'::jsonb,
  waveform jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create table public.sync_metadata (
  owner_id uuid primary key default auth.uid() references auth.users(id), last_synced_at timestamptz,
  client_schema_version int not null default 1
);

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.consents enable row level security;
alter table public.questionnaire_runs enable row level security;
alter table public.screening_sessions enable row level security;
alter table public.sync_metadata enable row level security;

create policy "owner profile" on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy "owner children" on public.children for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "owner consents" on public.consents for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "owner questionnaire" on public.questionnaire_runs for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "owner sessions" on public.screening_sessions for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "owner sync" on public.sync_metadata for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create or replace function public.sync_screening_bundle(bundle jsonb)
returns jsonb language plpgsql security invoker set search_path = public as $$
declare b jsonb; child_uuid uuid; consent_uuid uuid; q_uuid uuid; session_uuid uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  b := bundle;
  if (b->>'mode') = 'demo' then raise exception 'demo bundles cannot be synced'; end if;
  child_uuid := (b->>'child_id')::uuid; consent_uuid := (b->>'consent_id')::uuid;
  insert into children(id, owner_id, pseudonym, birth_date, gestational_weeks, anganwadi_id, district_code)
    values(child_uuid, auth.uid(), coalesce(b->>'pseudonym','local-child'), nullif(b->>'child_birth_date','')::date, nullif(b->>'gestational_weeks','')::int, b->>'anganwadi_id', b->>'district_code')
    on conflict (id) do update set pseudonym=excluded.pseudonym, birth_date=excluded.birth_date, gestational_weeks=excluded.gestational_weeks, anganwadi_id=excluded.anganwadi_id, district_code=excluded.district_code where children.owner_id=auth.uid();
  insert into consents(id, owner_id, child_id, version, granted_at)
    values(consent_uuid, auth.uid(), child_uuid, coalesce(b->>'consent_version','v1'), coalesce(nullif(b->>'session_date','')::timestamptz, now()))
    on conflict (id) do update set granted_at=excluded.granted_at where consents.owner_id=auth.uid();
  insert into questionnaire_runs(id, owner_id, child_id, engine_version, age_months, state, answers, analysis)
    values((b->>'questionnaire_run_id')::uuid, auth.uid(), child_uuid, coalesce(b->>'engine_version','mychild-engine'), (b->>'child_age_months')::int, b->>'questionnaire_state', coalesce(b->'answers','{}'), coalesce(b->'questionnaire_analysis','{}'))
    on conflict (id) do update set answers=excluded.answers, state=excluded.state, analysis=excluded.analysis;
  q_uuid := (b->>'questionnaire_run_id')::uuid;
  insert into screening_sessions(id, owner_id, child_id, questionnaire_run_id, consent_id, mode, analysis_status, risk_level, quality_reasons, vttl_ms, cvr_ratio, pfv_std, voiced_seconds, child_voiced_seconds, transition_count, audio_source, model_version, questionnaire_analysis, decision_trace, waveform, created_at)
    values((b->>'session_id')::uuid, auth.uid(), child_uuid, q_uuid, consent_uuid, 'live', b->>'analysis_status', b->>'risk_level', coalesce(b->'quality_reasons','[]'), (b->>'vttl_ms')::float8, (b->>'cvr_ratio')::float8, (b->>'pfv_std')::float8, (b->>'voiced_seconds')::float8, (b->>'child_voiced_seconds')::float8, (b->>'transition_count')::int, b->>'audio_source', b->>'model_version', coalesce(b->'questionnaire_analysis','{}'), coalesce(b->'decision_trace','[]'), coalesce(b->'waveform','[]'), coalesce(nullif(b->>'session_date','')::timestamptz, now()))
    on conflict (id) do update set analysis_status=excluded.analysis_status, risk_level=excluded.risk_level, questionnaire_analysis=excluded.questionnaire_analysis, decision_trace=excluded.decision_trace, waveform=excluded.waveform;
  session_uuid := (b->>'session_id')::uuid;
  insert into sync_metadata(owner_id,last_synced_at) values(auth.uid(),now()) on conflict(owner_id) do update set last_synced_at=excluded.last_synced_at;
  return jsonb_build_object('session_id', session_uuid, 'synced', true);
end; $$;

create or replace view public.child_screening_analysis as
select
  c.id as child_id,
  c.pseudonym,
  c.birth_date,
  c.gestational_weeks,
  c.anganwadi_id,
  c.district_code,
  s.id as session_id,
  s.created_at as screened_at,
  s.risk_level,
  s.analysis_status,
  s.quality_reasons,
  s.vttl_ms,
  s.cvr_ratio,
  s.pfv_std,
  s.voiced_seconds,
  s.child_voiced_seconds,
  s.transition_count,
  s.audio_source,
  q.age_months,
  q.state as questionnaire_state,
  q.answers,
  q.analysis as questionnaire_analysis,
  s.decision_trace,
  s.waveform
from public.children c
join public.screening_sessions s on s.child_id = c.id and s.owner_id = c.owner_id
left join public.questionnaire_runs q on q.id = s.questionnaire_run_id and q.owner_id = c.owner_id;
