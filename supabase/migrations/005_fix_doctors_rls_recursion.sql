-- Fix RLS recursion: doctors -> patients -> doctors.
-- Applied to the connected Supabase project on 2026-10-14.
-- Existing policy doctors_linked_guardian_read directly queried patients,
-- whose SELECT policies query doctors. Move the linked-guardian check into
-- a narrowly scoped SECURITY DEFINER helper to break recursive evaluation.
create or replace function public.is_linked_guardian_for_doctor(p_doctor_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $body$
  select auth.uid() is not null and exists (
    select 1 from public.patients p
    where p.doctor_id = p_doctor_id and p.user_id = auth.uid()
  );
$body$;
revoke all on function public.is_linked_guardian_for_doctor(uuid) from public, anon;
grant execute on function public.is_linked_guardian_for_doctor(uuid) to authenticated;
drop policy if exists doctors_linked_guardian_read on public.doctors;
create policy doctors_linked_guardian_read on public.doctors for select
to authenticated using (is_active and public.is_linked_guardian_for_doctor(id));
