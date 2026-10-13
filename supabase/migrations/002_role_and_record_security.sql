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
