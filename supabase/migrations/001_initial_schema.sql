-- ============================================================
-- عيادتي — Pediatric Clinic Manager
-- Supabase Migration: 001_initial_schema.sql
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── Enable Extensions ──────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Profiles (linked to auth.users) ────────────────────────
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  role        text not null default 'patient' check (role in ('admin','doctor','patient')),
  phone       text,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'patient')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Doctors ──────────────────────────────────────────────────
create table public.doctors (
  id                            uuid primary key default uuid_generate_v4(),
  user_id                       uuid not null references auth.users(id) on delete cascade,
  full_name                     text not null,
  specialty                     text,
  phone                         text,
  email                         text,
  avatar_url                    text,
  license_number                text,
  bio                           text,
  available_days                integer[] not null default '{1,2,3,4,6}',
  work_start_time               text not null default '08:00',
  work_end_time                 text not null default '17:00',
  appointment_duration_minutes  integer not null default 20,
  is_active                     boolean not null default true,
  created_at                    timestamptz not null default now()
);

-- ── Patients ──────────────────────────────────────────────────
create table public.patients (
  id                uuid primary key default uuid_generate_v4(),
  doctor_id         uuid not null references public.doctors(id) on delete cascade,
  user_id           uuid references auth.users(id),
  full_name         text not null,
  date_of_birth     date not null,
  gender            text not null default 'male' check (gender in ('male','female')),
  blood_type        text,
  weight            numeric(5,2),
  height            numeric(5,2),
  guardian_name     text not null default '',
  guardian_phone    text not null default '',
  guardian_email    text,
  address           text,
  notes             text,
  allergies         text,
  chronic_diseases  text,
  treatment_status  text not null default 'under_treatment' check (treatment_status in ('under_treatment','recovered')),
  next_visit_date   date,
  avatar_url        text,
  allow_chat        boolean not null default true,
  allow_photos      boolean not null default true,
  allow_voice       boolean not null default true,
  allow_messages    boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz
);

-- ── Appointments ──────────────────────────────────────────────
create table public.appointments (
  id                uuid primary key default uuid_generate_v4(),
  patient_id        uuid not null references public.patients(id) on delete cascade,
  doctor_id         uuid not null references public.doctors(id) on delete cascade,
  patient_name      text not null default '',
  appointment_date  date not null,
  appointment_time  text not null,
  status            text not null default 'pending' check (status in ('pending','confirmed','cancelled','completed')),
  reason            text,
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz
);

-- ── Examinations ──────────────────────────────────────────────
create table public.examinations (
  id               uuid primary key default uuid_generate_v4(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  doctor_id        uuid not null references public.doctors(id),
  type             text not null default 'general'
                     check (type in ('general','vision','hearing','growth','blood')),
  examination_date date not null,
  result           text,
  notes            text,
  left_eye_vision  text,
  right_eye_vision text,
  weight_at_exam   numeric(5,2),
  height_at_exam   numeric(5,2),
  created_at       timestamptz not null default now()
);

-- ── Growth Records ────────────────────────────────────────────
create table public.growth_records (
  id                 uuid primary key default uuid_generate_v4(),
  patient_id         uuid not null references public.patients(id) on delete cascade,
  record_date        date not null,
  weight             numeric(5,2),
  height             numeric(5,2),
  head_circumference numeric(5,2),
  notes              text,
  created_at         timestamptz not null default now()
);

-- ── Vaccinations ──────────────────────────────────────────────
create table public.vaccinations (
  id            uuid primary key default uuid_generate_v4(),
  patient_id    uuid not null references public.patients(id) on delete cascade,
  doctor_id     uuid not null references public.doctors(id),
  vaccine_name  text not null,
  date_given    date,
  next_due_date date,
  status        text not null default 'due' check (status in ('given','due','overdue')),
  dose_number   integer not null default 1,
  batch_number  text,
  side_effects  text,
  notes         text,
  created_at    timestamptz not null default now()
);

-- ── Medications ───────────────────────────────────────────────
create table public.medications (
  id           uuid primary key default uuid_generate_v4(),
  doctor_id    uuid not null references public.doctors(id) on delete cascade,
  name         text not null,
  generic_name text,
  form         text, -- tablet, syrup, injection, drops, cream
  strength     text,
  notes        text,
  created_at   timestamptz not null default now()
);

-- ── Prescriptions ─────────────────────────────────────────────
create table public.prescriptions (
  id              uuid primary key default uuid_generate_v4(),
  patient_id      uuid not null references public.patients(id) on delete cascade,
  doctor_id       uuid not null references public.doctors(id),
  medication_id   uuid not null references public.medications(id),
  medication_name text not null default '',
  dosage          text not null,
  frequency       text not null,
  duration_days   integer not null default 7,
  instructions    text,
  prescribed_at   timestamptz not null default now()
);

-- ── Conversations ─────────────────────────────────────────────
create table public.conversations (
  id              uuid primary key default uuid_generate_v4(),
  patient_id      uuid not null references auth.users(id),
  doctor_id       uuid not null references public.doctors(id),
  patient_name    text not null default '',
  doctor_name     text not null default '',
  last_message    text,
  last_message_at timestamptz,
  unread_count    integer not null default 0,
  created_at      timestamptz not null default now(),
  unique(patient_id, doctor_id)
);

-- ── Messages ──────────────────────────────────────────────────
create table public.messages (
  id              uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references auth.users(id),
  sender_name     text not null default '',
  content         text,
  media_url       text,
  media_type      text,
  is_read         boolean not null default false,
  created_at      timestamptz not null default now()
);

-- ── Media Files ───────────────────────────────────────────────
create table public.media_files (
  id               uuid primary key default uuid_generate_v4(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  uploaded_by      uuid not null references auth.users(id),
  type             text not null, -- image, audio, pdf, document
  url              text not null,
  file_name        text,
  file_size_bytes  integer,
  mime_type        text,
  caption          text,
  created_at       timestamptz not null default now()
);

-- ── Safety Tips ───────────────────────────────────────────────
create table public.safety_tips (
  id            uuid primary key default uuid_generate_v4(),
  title         text not null,
  body          text not null,
  icon          text,
  locale        text not null default 'ar',
  display_order integer not null default 0,
  created_at    timestamptz not null default now()
);

-- ── Failed Operations ─────────────────────────────────────────
create table public.failed_operations (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid references auth.users(id),
  type        text not null,
  payload     jsonb,
  error       text,
  retries     integer not null default 0,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles      enable row level security;
alter table public.doctors        enable row level security;
alter table public.patients       enable row level security;
alter table public.appointments   enable row level security;
alter table public.examinations   enable row level security;
alter table public.growth_records enable row level security;
alter table public.vaccinations   enable row level security;
alter table public.medications    enable row level security;
alter table public.prescriptions  enable row level security;
alter table public.conversations  enable row level security;
alter table public.messages       enable row level security;
alter table public.media_files    enable row level security;
alter table public.safety_tips    enable row level security;

-- Profiles: own row
create policy "profiles_self" on public.profiles
  for all using (auth.uid() = id);

-- Doctors: own record; admin sees all
create policy "doctors_own" on public.doctors
  for all using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Patients: doctor sees own patients; patient sees self
create policy "patients_doctor_or_self" on public.patients
  for all using (
    exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
    or auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Appointments: doctor or patient
create policy "appointments_access" on public.appointments
  for all using (
    auth.uid() = patient_id
    or exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
  );

-- Examinations / Growth / Vaccinations / Prescriptions: doctor of that patient
create policy "examinations_access" on public.examinations
  for all using (
    exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
    or exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid())
  );

create policy "growth_records_access" on public.growth_records
  for all using (
    exists (
      select 1 from public.patients p
      join public.doctors d on d.id = p.doctor_id
      where p.id = patient_id and (d.user_id = auth.uid() or p.user_id = auth.uid())
    )
  );

create policy "vaccinations_access" on public.vaccinations
  for all using (
    exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
    or exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid())
  );

create policy "medications_own_doctor" on public.medications
  for all using (
    exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
  );

create policy "prescriptions_access" on public.prescriptions
  for all using (
    exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
    or exists (select 1 from public.patients p where p.id = patient_id and p.user_id = auth.uid())
  );

-- Conversations & Messages: participant
create policy "conversations_participant" on public.conversations
  for all using (
    auth.uid() = patient_id
    or exists (select 1 from public.doctors d where d.id = doctor_id and d.user_id = auth.uid())
  );

create policy "messages_participant" on public.messages
  for all using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
      and (c.patient_id = auth.uid() or exists (
        select 1 from public.doctors d where d.id = c.doctor_id and d.user_id = auth.uid()
      ))
    )
  );

-- Media Files
create policy "media_access" on public.media_files
  for all using (
    auth.uid() = uploaded_by
    or exists (
      select 1 from public.patients p
      join public.doctors d on d.id = p.doctor_id
      where p.id = patient_id and (d.user_id = auth.uid() or p.user_id = auth.uid())
    )
  );

-- Safety tips: readable by all authenticated users
create policy "safety_tips_read" on public.safety_tips
  for select using (auth.role() = 'authenticated');

-- ============================================================
-- INDEXES
-- ============================================================
create index idx_patients_doctor_id      on public.patients(doctor_id);
create index idx_patients_user_id        on public.patients(user_id);
create index idx_appointments_doctor     on public.appointments(doctor_id, appointment_date);
create index idx_appointments_patient    on public.appointments(patient_id);
create index idx_examinations_patient    on public.examinations(patient_id);
create index idx_vaccinations_patient    on public.vaccinations(patient_id);
create index idx_messages_conversation   on public.messages(conversation_id, created_at);
create index idx_conversations_patient   on public.conversations(patient_id);
create index idx_conversations_doctor    on public.conversations(doctor_id);

-- ============================================================
-- STORAGE BUCKETS (run in Supabase Storage panel OR via API)
-- ============================================================
-- insert into storage.buckets (id, name, public) values ('patient-media', 'patient-media', false);
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
