# عيادتي – Pediatric Clinic Manager

<div align="center">
  <img src="assets/images/logo.png" alt="عيادتي Logo" width="120" />
  <h3>نظام إدارة عيادة الأطفال</h3>
  <p>A full-featured Flutter + Supabase pediatric clinic management system</p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
  ![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)
  ![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
  ![License](https://img.shields.io/badge/License-MIT-yellow)
</div>

---

## ✨ Features

| Module | Description |
|--------|-------------|
| 🔐 Auth | Role-based login (Admin / Doctor / Patient) |
| 👶 Patients | Full patient profiles, media attachments |
| 📅 Appointments | Calendar, booking, status management |
| 💊 Medications | Prescriptions per visit |
| 🩺 Examinations | Record keeping with growth charts |
| 💉 Vaccinations | Schedule tracking (given / due / overdue) |
| 💬 Chat | Real-time messaging (Supabase Realtime) |
| 📄 PDF Reports | Arabic PDF generation |
| 🛡️ Admin Panel | Manage doctors, toggle status |
| ⚙️ Settings | Dark mode, language (AR/EN), logout |

---

## 🏗️ Architecture

```
lib/
├── core/               # Constants, theme, router, config
├── data/               # Models, datasources, repository implementations
├── domain/             # Repository interfaces (abstract)
├── presentation/       # Screens, BLoCs, widgets
└── main.dart
```

**State Management:** BLoC pattern  
**Navigation:** GoRouter with auth guards  
**Backend:** Supabase (Auth, DB, Storage, Realtime)  
**Local Storage:** Hive (settings), flutter_secure_storage  

---

## 🚀 Getting Started

### 1. Prerequisites

- Flutter SDK ≥ 3.19.0
- Dart SDK ≥ 3.3.0
- A [Supabase](https://supabase.com) account

### 2. Clone & Install

```bash
git clone https://github.com/Thanoon12k/Pediatric-Clinic-manager.git
cd "Pediatric Clinic manager"
flutter pub get
```

### 3. Configure Supabase

Open `lib/core/config/env_config.dart` and fill in your project values:

```dart
static const String supabaseUrl     = 'https://zmplunreqqmvqoyrrceq.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY'; // from Supabase Dashboard → Settings → API
```

> **Where to find your anon key:**  
> Supabase Dashboard → Your Project → Project Settings → API → **anon / public**

### 4. Run Database Migration

Go to your **Supabase SQL Editor** and run the migration file:

```
supabase/migrations/001_initial_schema.sql
```

This creates all tables: `profiles`, `patients`, `appointments`, `examinations`, `vaccinations`, `medications`, `messages`, `media_files`, `failed_operations`.

### 5. Run the App

```bash
flutter run
```

---

## 👤 Default Roles

| Role | Access |
|------|--------|
| `admin` | Manage doctors, full system access |
| `doctor` | Own patients, appointments, full clinical features |
| `patient` | View own profile, book appointments, chat |

---

## 🗄️ Supabase Setup

**Project ref:** `zmplunreqqmvqoyrrceq`

```bash
# Link local project to Supabase
supabase login
supabase link --project-ref zmplunreqqmvqoyrrceq

# Push migrations
supabase db push
```

### Storage Buckets Required

Create these buckets in **Supabase Storage**:
- `patient-media` — patient photos, audio, files (private, RLS enforced)

---

## 🔒 Environment Variables

Copy `.env.example` to `.env` and fill in values. **Never commit `.env`.**

```bash
cp .env.example .env
```

---

## 🧪 Running Tests

```bash
flutter test
```

Tests use `mocktail` — no code generation required.

---

## 📦 Key Dependencies

```yaml
flutter_bloc: ^8.1.6      # State management
go_router: ^14.6.2         # Navigation
supabase_flutter: ^2.7.0   # Backend
hive_flutter: ^1.1.0       # Local storage
fl_chart: ^0.70.2          # Growth charts
table_calendar: ^3.2.0     # Calendar
flutter_animate: ^4.5.2    # Animations
pdf + printing             # PDF reports
```

---

## 📸 Screenshots

> Coming soon — run the app and take screenshots with `flutter screenshot`

---

## 📝 License

MIT © 2024 [Thanoon12k](https://github.com/Thanoon12k)
