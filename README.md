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
