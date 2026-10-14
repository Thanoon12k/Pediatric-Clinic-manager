-- 004: staff username registry + doctor's opt-in promotion of queue to medical record.
-- Requires migrations 001, 002 and 003. First test on staging; BACK UP production.
-- Do not directly grant creation rights to authenticated users.

create table if not exists public.staff_usernames (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint staff_username_format check (username ~ '^[a-z][a-z0-9_]{3,23}$')
);

alter table public.staff_usernames enable row level security;
revoke all on public.staff_usernames from public, anon, authenticated;
-- Only trusted service_role backend may manage staff username mapping.

alter table public.clinic_queue
  add column if not exists medical_patient_id uuid
    references public.patients(id) on delete set null;

create unique index if not exists clinic_queue_unique_medical_record_link
  on public.clinic_queue(medical_patient_id)
  where medical_patient_id is not null;

-- Only the assigned doctor (never a secretary) can link their queue row to
-- an actual medical patient file, after collecting the missing required data.
create or replace function public.link_clinic_queue_patient(
  p_queue_id uuid,
  p_medical_patient_id uuid
) returns void
language plpgsql security definer set search_path = ''
as $link$
declare
  v_queue public.clinic_queue%rowtype;
begin
  select * into v_queue from public.clinic_queue
    where id = p_queue_id for update;

  if not found then
    raise exception 'Queue item does not exist';
  end if;

  if not exists (
    select 1 from public.doctors d
    join public.profiles p on p.id = d.user_id
    where d.id = v_queue.doctor_id
      and d.user_id = auth.uid()
      and p.role = 'doctor'
      and d.is_active
  ) then
    raise exception 'Doctor-only action' using errcode = '42501';
  end if;

  if v_queue.medical_patient_id is not null then
    raise exception 'This queue entry already has a medical record';
  end if;

  if not exists (
    select 1 from public.patients p
    where p.id = p_medical_patient_id
      and p.doctor_id = v_queue.doctor_id
  ) then
    raise exception 'Patient does not belong to this doctor';
  end if;

  update public.clinic_queue
    set medical_patient_id = p_medical_patient_id, updated_at = now()
    where id = p_queue_id;
end;
$link$;

revoke all on function public.link_clinic_queue_patient(uuid, uuid)
  from public, anon;
grant execute on function public.link_clinic_queue_patient(uuid, uuid)
  to authenticated;

-- Admin bootstrap must happen in SQL Editor only (never from the client).
-- The Edge Function creates fresh users with a private internal email alias
-- based on their case-normalized username.
