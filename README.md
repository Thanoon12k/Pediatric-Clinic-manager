# عيادتي | Pediatric Clinic Manager

Flutter + Supabase pediatric clinic system for doctors, patients and clinic administrators.

## Clinical calm redesign (v1.1)

- Warm off-white surfaces, gentle medical teal and neutral secondary colors.
- Arabic-first Tajawal typography and responsive Material 3 navigation.
- Doctor home: today's appointments, patient overview, shortcuts, quick actions.
- Doctor tabs: local patient search, appointment status filters, responsive tablet navigation rail.
- Working links to chat, medications, settings, profile and safety information.
- A dedicated pediatric launcher vector icon (`assets/icons/clinic_mark.svg`).
- Android network permission and safe fallback for unsigned local release builds.
- Helpful configuration-required screen if backend configuration is missing.

Existing functionality and data models remain in place; Supabase records are **not modified** by the redesign.

## Restore a doctor's forgotten password (Android)

1. Open Supabase Dashboard → Authentication → URL Configuration for the matching project.
2. Add the **exact** allowed redirect URL `com.thanoon.yadati://login-callback/` under Redirect URLs. Do not rely on the default `http://localhost:3000`.
3. Build and install version `1.1.1+3` or later on the **same Android phone** that will request password recovery.
4. In Yadati, choose "نسيت كلمة المرور؟" and request an email using the original doctor's login email.
5. On the **same phone**, open the **newest** password reset email and tap its link. The link opens Yadati's password update form, not localhost. Select a strong new password.
6. Log in with the old email and new password. Existing `auth.users.id` and `doctors.user_id` remain unchanged.

Important: Recovery URLs carry one-time credentials; never share them in chat or screenshots. Links sent before the redirect fix must be discarded. The callback URL must be allowlisted in Supabase Dashboard or Supabase will fall back to Site URL. PKCE recovery should be requested and completed on the same Android installation.

## Required database security update

After taking a backup and validating on a staging Supabase project, apply:
`supabase/migrations/002_role_and_record_security.sql`.

The migration blocks self-assigned privileged roles, allows guardians to read only their linked children's data, adds a server-side safe availability service, prevents two active appointments in the same slot, and secures message read receipts.

**Important:** Public guardian registration creates a patient account. Clinic staff must link the guardian's `auth.users.id` to `patients.user_id` for each child before online booking works. Existing admins and doctors retain their roles. The unique appointment index requires resolving any existing duplicate non-cancelled slots first. Do not deploy a backend-connected APK to a clinical production database until this migration is tested and applied.

## Configure backend before release

An installable APK may build without credentials, but it displays a configuration screen until the **public** Supabase URL and anon/publishable key are set. Never put the `service_role` key in the app.

Pass the public configuration to Flutter at build time:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
```

For GitHub Actions, configure repository secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` under **Settings → Secrets and variables → Actions**, then run the **Android APK and Flutter checks** workflow. Download `yadati-android-apk` from the workflow run's **Artifacts** section.

The CI-built release APK is **debug-signed for internal testing** when `android/key.properties` is absent. Set up a permanent release keystore before any Play Store publication or update to an existing production app.

## Development and quality checks

```bash
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Android configuration is in `android/app/build.gradle.kts`. The app targets Arabic and English and uses Material 3 widgets. A large part of the underlying screens, data access and auth flows rely on an existing Supabase database and permissions: validate all workflows against **test accounts and non-identifiable test data** before clinical use.

## Modules

Patient records • Appointments • Examination records • Medications • Vaccinations • Growth charts • Conversations • PDF reports • Clinic administration • Settings.

© Project contributors. See LICENSE.txt.
