-- 003: One-doctor secretary accounts + minimal-data daily clinic queue.
-- IMPORTANT: Back up and test migrations 001 and 002 before applying 003.
-- Apply with a trusted database administrator only. Never ship service_role
-- credentials, grant privileged roles, or write secretary assignments in Flutter.

-- Adding 'secretary' to the existing roles does NOT let public signups choose it.
-- Migration 002's handle_new_user() always creates 'patient', and its trigger
-- rejects client-side promotion.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('admin', 'doctor', 'patient', 'secretary'));

-- One row per secretary = no cross-doctor or multi-doctor access.
create table if not exists public.secretary_assignments (
  user_id uuid primary key references auth.users(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists secretary_assignments_doctor_idx
  on public.secretary_assignments(doctor_id);
alter table public.secretary_assignments enable row level security;
revoke all on public.secretary_assignments from public, anon, authenticated;
grant select on public.secretary_assignments to authenticated;
drop policy if exists secretary_reads_own_assignment on public.secretary_assignments;
create policy secretary_reads_own_assignment
  on public.secretary_assignments for select to authenticated
  using (user_id = (select auth.uid()));

-- Reception queue is deliberately separate from medical records, appointments,
-- prescriptions and examinations. Store only the minimum name needed to call
-- a patient; avoid symptoms, diagnosis, phone, notes and medical identifiers.
create table if not exists public.clinic_queue (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  visit_date date not null default ((now() at time zone 'Asia/Baghdad')::date),
  token_number integer not null check (token_number > 0),
  sort_order integer not null check (sort_order > 0),
  patient_name text not null check (
    char_length(btrim(patient_name)) between 1 and 100
  ),
  status text not null default 'waiting' check (
    status in ('waiting', 'in_progress', 'completed', 'cancelled')
  ),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (doctor_id, visit_date, token_number)
);
create index if not exists clinic_queue_day_idx
  on public.clinic_queue(doctor_id, visit_date, sort_order);
create unique index if not exists clinic_queue_one_patient_in_progress
  on public.clinic_queue(doctor_id, visit_date)
  where status = 'in_progress';
alter table public.clinic_queue enable row level security;
revoke all on public.clinic_queue from public, anon, authenticated;
grant select on public.clinic_queue to authenticated;

-- Check role from profiles (not user-editable signup metadata) AND the bound
-- doctor's auth user / active secretary assignment. No multi-doctor scope.
create or replace function public.can_manage_clinic_queue(p_doctor_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and (
    exists (
      select 1 from public.profiles p
      join public.doctors d on d.user_id = p.id
      where p.id = auth.uid() and p.role = 'doctor'
        and d.id = p_doctor_id and d.is_active
    )
    or exists (
      select 1 from public.profiles p
      join public.secretary_assignments a on a.user_id = p.id
      join public.doctors d on d.id = a.doctor_id
      where p.id = auth.uid() and p.role = 'secretary'
        and a.doctor_id = p_doctor_id and a.is_active and d.is_active
    )
  );
$$;
revoke all on function public.can_manage_clinic_queue(uuid) from public, anon;
grant execute on function public.can_manage_clinic_queue(uuid) to authenticated;

drop policy if exists clinic_queue_staff_read on public.clinic_queue;
create policy clinic_queue_staff_read on public.clinic_queue
  for select to authenticated
  using (public.can_manage_clinic_queue(doctor_id));
-- No INSERT / UPDATE / DELETE policies. Mutations happen ONLY through RPC.

-- Get exactly the current doctor's identity or a secretary's assigned doctor.
-- Does not grant receptionist SELECT over the doctors or patients tables.
create or replace function public.clinic_queue_context()
returns table(doctor_id uuid, doctor_name text, account_role text)
language plpgsql stable security definer set search_path = ''
as $$
declare v_role text;
begin
  select p.role into v_role from public.profiles p where p.id = auth.uid();
  if v_role = 'doctor' then
    return query select d.id, d.full_name, v_role
      from public.doctors d
      where d.user_id = auth.uid() and d.is_active limit 1;
  elsif v_role = 'secretary' then
    return query select d.id, d.full_name, v_role
      from public.secretary_assignments a
      join public.doctors d on d.id = a.doctor_id
      where a.user_id = auth.uid() and a.is_active and d.is_active
      limit 1;
  end if;
end;
$$;
revoke all on function public.clinic_queue_context() from public, anon;
grant execute on function public.clinic_queue_context() to authenticated;

-- Allocate a daily token atomically (avoid concurrent reception duplicates).
create or replace function public.add_clinic_queue_patient(
  p_doctor_id uuid, p_patient_name text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Baghdad')::date;
  v_token integer;
  v_order integer;
  v_id uuid;
  v_name text := btrim(coalesce(p_patient_name,''));
begin
  if not public.can_manage_clinic_queue(p_doctor_id) then
    raise exception 'Queue access denied' using errcode = '42501';
  end if;
  if char_length(v_name) not between 1 and 100 then
    raise exception 'Patient name must be between 1 and 100 characters';
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended(p_doctor_id::text || ':' || v_today::text, 0));
  select coalesce(max(token_number),0)+1, coalesce(max(sort_order),0)+10
  into v_token,v_order from public.clinic_queue
  where doctor_id = p_doctor_id and visit_date = v_today;
  insert into public.clinic_queue(
    doctor_id, visit_date, token_number, sort_order, patient_name, created_by)
  values (p_doctor_id,v_today,v_token,v_order,v_name,auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.add_clinic_queue_patient(uuid,text) from public, anon;
grant execute on function public.add_clinic_queue_patient(uuid,text) to authenticated;

-- Only safe reception workflow transitions; no editing medical fields.
create or replace function public.set_clinic_queue_status(
  p_queue_id uuid, p_status text
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_queue public.clinic_queue%rowtype;
  v_today date := (now() at time zone 'Asia/Baghdad')::date;
begin
  select * into v_queue from public.clinic_queue where id = p_queue_id;
  if not found or not public.can_manage_clinic_queue(v_queue.doctor_id)
      or v_queue.visit_date <> v_today then
    raise exception 'Queue item not available' using errcode = '42501';
  end if;
  if not (
    (v_queue.status = 'waiting' and p_status in ('in_progress','cancelled'))
    or (v_queue.status = 'in_progress' and p_status in ('waiting','completed','cancelled'))
    or (v_queue.status = 'cancelled' and p_status = 'waiting')
  ) then
    raise exception 'Invalid queue status transition';
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended(v_queue.doctor_id::text || ':' || v_today::text, 0));
  -- Serialize status changes and protect against concurrent stale requests.
  select * into v_queue from public.clinic_queue where id = p_queue_id for update;
  if not (
    (v_queue.status = 'waiting' and p_status in ('in_progress','cancelled'))
    or (v_queue.status = 'in_progress' and p_status in ('waiting','completed','cancelled'))
    or (v_queue.status = 'cancelled' and p_status = 'waiting')
  ) then
    raise exception 'Status changed; refresh queue first';
  end if;
  update public.clinic_queue set status = p_status, updated_at = now()
    where id = p_queue_id;
end;
$$;
revoke all on function public.set_clinic_queue_status(uuid,text) from public, anon;
grant execute on function public.set_clinic_queue_status(uuid,text) to authenticated;

-- Reorder ALL waiting items for the assigned doctor and Baghdad-local day.
-- Validate exact queue ID set to block edits to another doctor's list.
create or replace function public.reorder_clinic_queue(
  p_doctor_id uuid, p_ordered_ids uuid[]
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Baghdad')::date;
  v_expected uuid[];
  v_provided uuid[];
begin
  if not public.can_manage_clinic_queue(p_doctor_id) then
    raise exception 'Queue access denied' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended(p_doctor_id::text || ':' || v_today::text, 0));
  select array_agg(q.id order by q.id) into v_expected
    from public.clinic_queue q
    where q.doctor_id = p_doctor_id and q.visit_date = v_today
      and q.status = 'waiting';
  select array_agg(x.id order by x.id) into v_provided
    from unnest(p_ordered_ids) as x(id);
  if v_expected is distinct from v_provided
     or coalesce(cardinality(p_ordered_ids),0)
        <> coalesce(cardinality(v_expected),0) then
    raise exception 'Queue changed; refresh and try again';
  end if;
  update public.clinic_queue q
    set sort_order = x.ordinality::integer * 10, updated_at = now()
    from unnest(p_ordered_ids) with ordinality as x(id, ordinality)
    where q.id = x.id and q.doctor_id = p_doctor_id
      and q.visit_date = v_today and q.status = 'waiting';
end;
$$;
revoke all on function public.reorder_clinic_queue(uuid,uuid[]) from public, anon;
grant execute on function public.reorder_clinic_queue(uuid,uuid[]) to authenticated;

-- The legacy schema left this potentially sensitive JSON payload table without
-- RLS. Local retry UI uses Hive, so no general client access is needed.
alter table public.failed_operations enable row level security;
revoke all on public.failed_operations from public, anon, authenticated;
grant select, insert on public.failed_operations to authenticated;
drop policy if exists failed_operations_own_read on public.failed_operations;
drop policy if exists failed_operations_own_insert on public.failed_operations;
create policy failed_operations_own_read on public.failed_operations
  for select to authenticated using (user_id = (select auth.uid()));
create policy failed_operations_own_insert on public.failed_operations
  for insert to authenticated with check (user_id = (select auth.uid()));

-- Provisioning example (SQL Editor ONLY, after Auth → Users account exists):
--   update public.profiles set role='secretary' where id='<SECRETARY_USER_UUID>';
--   insert into public.secretary_assignments(user_id,doctor_id)
--     values ('<SECRETARY_USER_UUID>','<EXISTING_DOCTOR_UUID>');
-- Verify the doctor's UUID belongs to the correct clinic, and that the
-- secretary's old role has no doctor/admin duties before promotion.
