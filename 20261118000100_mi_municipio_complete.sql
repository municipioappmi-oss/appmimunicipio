-- MI MUNICIPIO: complementos de participación ciudadana y evidencias.
-- Aplicar en Supabase SQL Editor después de revisar el proyecto existente.
-- No modifica ni elimina reportes, perfiles o políticas ya existentes.

create table if not exists public.surveys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  municipality text not null default 'Ambos municipios',
  is_active boolean not null default true,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.survey_options (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references public.surveys(id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.survey_votes (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references public.surveys(id) on delete cascade,
  option_id uuid not null references public.survey_options(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint survey_votes_one_per_user unique (survey_id, user_id)
);

create index if not exists surveys_active_idx on public.surveys (is_active, starts_at, ends_at);
create index if not exists survey_options_survey_idx on public.survey_options (survey_id);
create index if not exists survey_votes_survey_idx on public.survey_votes (survey_id);

alter table public.surveys enable row level security;
alter table public.survey_options enable row level security;
alter table public.survey_votes enable row level security;

grant select on public.surveys, public.survey_options to anon, authenticated;
grant select on public.announcements to anon;
grant insert, update, delete on public.surveys, public.survey_options to authenticated;
grant insert on public.survey_votes to authenticated;

 drop policy if exists announcements_public_read on public.announcements;
create policy announcements_public_read on public.announcements
for select to anon using (true);

create or replace function private.is_system_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $fn$
  select exists (select 1 from public.profiles p where p.user_id = (select auth.uid()) and p.role = 'system_admin');
$fn$;
revoke all on function private.is_system_admin() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_system_admin() to authenticated;

drop policy if exists profiles_system_admin_read on public.profiles;
create policy profiles_system_admin_read on public.profiles
for select to authenticated using (private.is_system_admin());

 drop policy if exists surveys_public_read on public.surveys;
create policy surveys_public_read on public.surveys
for select to anon, authenticated
using (is_active = true and starts_at <= now() and (ends_at is null or ends_at >= now()));

 drop policy if exists surveys_admin_write on public.surveys;
create policy surveys_admin_write on public.surveys
for all to authenticated
using (public.is_admin()) with check (public.is_admin() and created_by = (select auth.uid()));

 drop policy if exists survey_options_public_read on public.survey_options;
create policy survey_options_public_read on public.survey_options
for select to anon, authenticated
using (exists (select 1 from public.surveys s where s.id = survey_id and s.is_active = true and s.starts_at <= now() and (s.ends_at is null or s.ends_at >= now())));

 drop policy if exists survey_options_admin_write on public.survey_options;
create policy survey_options_admin_write on public.survey_options
for all to authenticated
using (public.is_admin()) with check (public.is_admin());

 drop policy if exists survey_votes_self_insert on public.survey_votes;
create policy survey_votes_self_insert on public.survey_votes
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.surveys s
    join public.survey_options o on o.survey_id = s.id
    where s.id = survey_votes.survey_id and o.id = survey_votes.option_id and s.is_active = true
      and s.starts_at <= now() and (s.ends_at is null or s.ends_at >= now())
  )
);

-- Evidencia privada de reportes. La aplicación almacena primero el objeto y
-- después registra su ruta en report_files. Los objetos no son públicos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('report-evidence', 'report-evidence', false, 10485760, array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public = false, file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','application/pdf'];

 drop policy if exists mm_report_evidence_upload on storage.objects;
create policy mm_report_evidence_upload on storage.objects
for insert to authenticated
with check (
  bucket_id = 'report-evidence'
  and case
    when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.can_send_report_file(split_part(name, '/', 1)::uuid)
    else false
  end
);

 drop policy if exists mm_report_evidence_read on storage.objects;
create policy mm_report_evidence_read on storage.objects
for select to authenticated
using (
  bucket_id = 'report-evidence'
  and exists (
    select 1 from public.report_files f
    where f.storage_path = name and public.can_access_report(f.report_id)
  )
);
