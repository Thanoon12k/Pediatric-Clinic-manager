-- Migration 002: tighten authority over patient records and account roles.
-- Apply in a staging project first; keep a backup of the existing database.
-- Existing data and existing admin/doctor roles are preserved.

-- Client-provided signup metadata must never grant privileged roles.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email, ''),
    'patient'
  );
  return new;
end;
$$;

-- Prevent an authenticated user from promoting their own profile.
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'Profile role changes require a trusted server';
  end if;
  return new;
end;
$$;
drop trigger if exists prevent_profile_role_escalation on public.profiles;
create trigger prevent_profile_role_escalation
before update on public.profiles
for each row execute function public.prevent_profile_role_escalation();

-- A profile should be readable/updatable by its owner but cannot be used
-- to authorize reading another user's healthcare information.
drop policy if exists "profiles_self" on public.profiles;
create policy "profiles_self_read" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy "profiles_self_update" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Patient reads are allowed for the linked guardian or owning doctor.
-- Changes to medical records remain doctor-only.
drop policy if exists "patients_doctor_or_self" on public.patients;
create policy "patients_read" on public.patients
  for select to authenticated using (
    user_id = (select auth.uid())
    or exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
    or exists (select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin')
  );
create policy "patients_insert" on public.patients
  for insert to authenticated with check (
    exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
  );
create policy "patients_update" on public.patients
  for update to authenticated
  using (exists (select 1 from public.doctors d
    where d.id = doctor_id and d.user_id = (select auth.uid())))
  with check (exists (select 1 from public.doctors d
    where d.id = doctor_id and d.user_id = (select auth.uid())));
create policy "patients_delete" on public.patients
  for delete to authenticated using (
    exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
  );

-- appointments.patient_id references public.patients, NOT auth.users.
-- The old policy compared unlike concepts and blocked guardian reads.
drop policy if exists "appointments_access" on public.appointments;
create policy "appointments_read" on public.appointments
  for select to authenticated using (
    exists (select 1 from public.patients p
      where p.id = patient_id and p.user_id = (select auth.uid()))
    or exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
  );
create policy "appointments_insert" on public.appointments
  for insert to authenticated with check (
    exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
    or exists (select 1 from public.patients p
      where p.id = patient_id and p.user_id = (select auth.uid())
        and p.doctor_id = doctor_id)
  );
create policy "appointments_update" on public.appointments
  for update to authenticated
  using (exists (select 1 from public.doctors d
    where d.id = doctor_id and d.user_id = (select auth.uid())))
  with check (exists (select 1 from public.doctors d
    where d.id = doctor_id and d.user_id = (select auth.uid())));
create policy "appointments_delete" on public.appointments
  for delete to authenticated using (
    exists (select 1 from public.doctors d
      where d.id = doctor_id and d.user_id = (select auth.uid()))
  );

-- Prevent a member of a conversation from impersonating another sender.
drop policy if exists "messages_participant" on public.messages;
create policy "messages_read" on public.messages
  for select to authenticated using (
    exists (select 1 from public.conversations c
      where c.id = conversation_id
        and (c.patient_id = (select auth.uid())
          or exists (select 1 from public.doctors d
            where d.id = c.doctor_id and d.user_id = (select auth.uid()))))
  );
create policy "messages_insert" on public.messages
  for insert to authenticated with check (
    sender_id = (select auth.uid())
    and exists (select 1 from public.conversations c
      where c.id = conversation_id
        and (c.patient_id = (select auth.uid())
          or exists (select 1 from public.doctors d
            where d.id = c.doctor_id and d.user_id = (select auth.uid()))))
  );
-- Updating message content is intentionally disabled from clients until
-- a dedicated validated read-receipt operation is provided.


-- Guardians may see their assigned physician's public clinic profile.
create policy "doctors_linked_guardian_read" on public.doctors
  for select to authenticated using (
    is_active and exists (select 1 from public.patients p
      where p.doctor_id = id and p.user_id = (select auth.uid()))
  );

-- Limit the appointment conflict check to non-cancelled appointments.
-- If this fails due to existing duplicates, resolve them before retrying.
create unique index if not exists idx_appointments_active_doctor_slot
  on public.appointments (doctor_id, appointment_date, appointment_time)
  where status <> 'cancelled';

-- This function returns *only time slots*; no other patients' details can
-- be inspected by a guardian. It checks membership before bypassing RLS.
create or replace function public.available_appointment_slots(
  p_doctor_id uuid, p_date date)
returns table(slot text)
language plpgsql security definer set search_path = ''
as $$
declare
  doc record;
  current_slot timestamp;
  finish_slot timestamp;
  duration_minutes integer;
  formatted_time text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select d.work_start_time, d.work_end_time, d.appointment_duration_minutes,
         d.available_days
    into doc
    from public.doctors d
   where d.id = p_doctor_id
     and d.is_active
     and (
       d.user_id = auth.uid()
       or exists (select 1 from public.patients p
                  where p.doctor_id = d.id and p.user_id = auth.uid())
     );

  if not found or p_date is null then
    return;
  end if;

  if not (extract(dow from p_date)::integer = any(doc.available_days)) then
    return;
  end if;

  duration_minutes := greatest(5, least(coalesce(doc.appointment_duration_minutes, 20), 120));
  current_slot := p_date + doc.work_start_time::time;
  finish_slot := p_date + doc.work_end_time::time;

  while current_slot + make_interval(mins => duration_minutes) <= finish_slot loop
    formatted_time := to_char(current_slot, 'HH24:MI');
    if not exists (
      select 1 from public.appointments a
       where a.doctor_id = p_doctor_id
         and a.appointment_date = p_date
         and a.appointment_time = formatted_time
         and a.status <> 'cancelled'
    ) then
      slot := formatted_time;
      return next;
    end if;
    current_slot := current_slot + make_interval(mins => duration_minutes);
  end loop;
end;
$$;
revoke all on function public.available_appointment_slots(uuid, date) from public;
grant execute on function public.available_appointment_slots(uuid, date) to authenticated;
