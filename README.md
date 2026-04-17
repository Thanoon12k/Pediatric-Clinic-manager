# عيادتي — Pediatric Clinic Manager

**نظام إدارة عيادة طبيب الأطفال المتكامل**  
A full-featured Flutter + Supabase pediatric clinic management system supporting Arabic & English.

---

## 🚀 Features

| Module | Features |
|--------|----------|
| 🔐 Auth | Login, Register, Forgot Password, Role-based routing (Admin / Doctor / Patient) |
| 👨‍⚕️ Doctor | Dashboard, patient list with search, appointments calendar, quick actions |
| 👶 Patient | Profile, add/edit form, age display, guardian info, treatment status, permissions |
| 📅 Appointments | Calendar view, time slot generation, confirm/cancel/complete, patient booking |
| 🔬 Examinations | Vision, hearing, growth, blood, general exams with type-specific fields |
| 💉 Vaccinations | Add vaccines, track given/due/overdue, common vaccine library |
| 📊 Charts | Weight & height growth curves using fl_chart |
| 💊 Medications | Doctor's drug library grouped by form, add prescriptions per patient |
| 💬 Messages | Real-time patient ↔ doctor chat (Supabase Realtime) |
| 📄 PDF Reports | Generate & print/share Arabic patient reports |
| 🛡️ Safety Tips | 10 expandable pediatric safety topics |
| ⚙️ Settings | Dark mode, Arabic/English toggle, profile, logout |
| 🏥 Admin | Manage doctors — activate, deactivate, delete |
| 🔁 Failed Ops | Offline queue with retry/cancel |

---

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.35+ (Android + Web)
- **Backend**: Supabase (Auth, PostgreSQL, Realtime, Storage)
- **State**: BLoC / Cubit
- **Navigation**: GoRouter
- **DI**: GetIt
- **Storage**: Hive (local), Supabase Storage (media)
- **PDF**: `pdf` + `printing`
- **Charts**: `fl_chart`
- **Fonts**: Cairo (Arabic support)

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/        (env_config.dart)
│   ├── constants/     (app_constants.dart)
│   ├── di/            (injection.dart)
│   ├── router/        (app_router.dart)
│   └── theme/         (app_colors, app_text_styles, app_theme)
├── data/
│   ├── datasources/   (Supabase implementations)
│   ├── models/        (UserModel, PatientModel, etc.)
│   └── repositories/  (Implementations)
├── domain/
│   └── repositories/  (Abstract interfaces)
├── l10n/
│   ├── app_ar.arb
│   └── app_en.arb
├── presentation/
│   ├── blocs/         (AuthBloc, PatientBloc, AppointmentBloc, …)
│   ├── screens/       (All screens)
│   └── widgets/       (Shared widgets)
└── main.dart

supabase/
└── migrations/
    └── 001_initial_schema.sql

test/
├── unit/
│   ├── blocs/
│   └── models/
```

---

## ⚙️ Setup Guide

### 1. Clone the repo

```bash
git clone https://github.com/Thanoon12k/Pediatric-Clinic-manager.git
cd Pediatric-Clinic-manager
```

### 2. Create a Supabase project

- Go to [supabase.com](https://supabase.com) → New Project
- Copy your **Project URL** and **anon key**

### 3. Run the SQL migration

- In Supabase Dashboard → **SQL Editor**
- Paste contents of `supabase/migrations/001_initial_schema.sql`
- Click **Run**

### 4. Create Storage Buckets

In Supabase → Storage:
- Create bucket: `patient-media` (private)
- Create bucket: `avatars` (public)

### 5. Configure environment

```bash
cp lib/core/config/env_config.dart.example lib/core/config/env_config.dart
```

Edit `env_config.dart`:
```dart
static const String supabaseUrl  = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 6. Install dependencies

```bash
flutter pub get
```

### 7. Run the app

```bash
flutter run -d chrome    # Web
flutter run              # Android
```

---

## 🧪 Running Tests

```bash
# Generate mocks first
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test
```

---

## 🔐 Security

- All tables protected with **Row Level Security (RLS)**
- Doctors only see their own patients
- Patients only see their own records
- Admin can manage all doctors
- env_config.dart is in `.gitignore`
- Service role key never exposed to client

---

## 📱 Creating the First Admin

After running migrations, set a user's role to `admin` directly in Supabase:

```sql
update public.profiles set role = 'admin' where id = 'YOUR_USER_UUID';
```

Then create a matching doctor record and set `is_active = true`.

---

## 🌐 Localization

The app defaults to **Arabic (RTL)**. Toggle to English in Settings.  
Translation files: `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`

---

## 📦 Key Dependencies

```yaml
supabase_flutter: ^2.x    # Backend
flutter_bloc: ^9.x        # State management
go_router: ^14.x          # Navigation
get_it: ^8.x              # Dependency injection
hive_flutter: ^1.x        # Local storage
fl_chart: ^0.x            # Growth charts
pdf + printing: ^x.x      # PDF reports
table_calendar: ^3.x      # Appointment calendar
flutter_animate: ^4.x     # Animations
google_fonts: ^6.x        # Cairo font
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — free to use and modify.
