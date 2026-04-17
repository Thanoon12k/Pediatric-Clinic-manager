class AppConstants {
  AppConstants._();

  // ─── App ────────────────────────────────────────────────────────────────────
  static const String appName        = 'عيادتي';
  static const String appNameEn      = 'Yadati';
  static const String appVersion     = '1.0.0';

  // ─── Supabase Tables ────────────────────────────────────────────────────────
  static const String tableProfiles     = 'profiles';
  static const String tableDoctors      = 'doctors';
  static const String tablePatients     = 'patients';
  static const String tableAppointments = 'appointments';
  static const String tableExaminations = 'examinations';
  static const String tableGrowthRecords= 'growth_records';
  static const String tableVaccinations = 'vaccinations';
  static const String tableMedications  = 'medications';
  static const String tablePrescriptions= 'prescriptions';
  static const String tableMessages     = 'messages';
  static const String tableMediaFiles   = 'media_files';
  static const String tableSafetyTips   = 'safety_tips';
  static const String tableFailedOps    = 'failed_operations';
  static const String tableConversations= 'conversations';

  // ─── Supabase Storage Buckets ────────────────────────────────────────────────
  static const String bucketPatientMedia   = 'patient-media';
  static const String bucketProfileAvatars = 'avatars';

  // ─── Routes ──────────────────────────────────────────────────────────────────
  static const String routeSplash           = '/';
  static const String routeWelcome          = '/welcome';
  static const String routeLogin            = '/login';
  static const String routeRegister         = '/register';
  static const String routeForgotPassword   = '/forgot-password';
  static const String routeDoctorDashboard  = '/doctor';
  static const String routePatientDashboard = '/patient';
  static const String routeAdminDashboard   = '/admin';
  static const String routePatientList      = '/doctor/patients';
  static const String routeAppointments     = '/appointments';
  static const String routeAppointmentBook  = '/appointments/book';
  static const String routeMessages         = '/messages';
  static const String routeSettings         = '/settings';
  static const String routeMedications      = '/medications';
  static const String routeSafetyTips       = '/safety-tips';
  static const String routeFailedOps        = '/failed-ops';
  static const String routeDoctorProfile    = '/doctor/profile';

  // ─── Blood Types ─────────────────────────────────────────────────────────────
  static const List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // ─── Appointment Durations (minutes) ─────────────────────────────────────────
  static const List<int> appointmentDurations = [15, 20, 30, 45, 60];

  // ─── Hive Box Names ──────────────────────────────────────────────────────────
  static const String boxSettings      = 'settings';
  static const String boxOfflineQueue  = 'offline_queue';

  // ─── Settings Keys ───────────────────────────────────────────────────────────
  static const String keyLocale        = 'locale';
  static const String keyThemeMode     = 'theme_mode';
  static const String keyOnboardingDone= 'onboarding_done';
}
