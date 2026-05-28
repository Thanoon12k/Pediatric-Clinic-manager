import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/update_password_screen.dart';
import '../../presentation/screens/doctor/doctor_dashboard_screen.dart';
import '../../presentation/screens/doctor/doctor_profile_screen.dart';
import '../../presentation/screens/patient/patient_dashboard_screen.dart';
import '../../presentation/screens/patient/patient_list_screen.dart';
import '../../presentation/screens/patient/patient_profile_screen.dart';
import '../../presentation/screens/patient/patient_form_screen.dart';
import '../../presentation/screens/appointment/appointments_screen.dart';
import '../../presentation/screens/examination/examinations_screen.dart';
import '../../presentation/screens/vaccination/vaccinations_screen.dart';
import '../../presentation/screens/charts/charts_screen.dart';
import '../../presentation/screens/message/messages_screen.dart';
import '../../presentation/screens/medication/medications_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/safety/safety_tips_screen.dart';
import '../../presentation/screens/failed_ops/failed_operations_screen.dart';
import '../../presentation/screens/pdf/pdf_report_screen.dart';

// ─── Password-recovery deep-link handling ────────────────────────────────────
// Call this once after Supabase.initialize() to intercept the recovery event.
void setupAuthRedirectListener(GoRouter router) {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      router.go(AppConstants.routeUpdatePassword);
    }
  });
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeWelcome,
      builder: (_, __) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.routeForgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppConstants.routeUpdatePassword,
      builder: (_, __) => const UpdatePasswordScreen(),
    ),

    // ── Doctor ────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeDoctorDashboard,
      builder: (_, __) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: AppConstants.routeDoctorProfile,
      builder: (_, __) => const DoctorProfileScreen(),
    ),

    // ── Patients ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routePatientList,
      builder: (_, __) => const PatientListScreen(),
    ),
    GoRoute(
      path: '/doctor/patients/add',
      builder: (_, __) => const PatientFormScreen(),
    ),
    GoRoute(
      path: '/doctor/patients/:id',
      builder: (_, state) => PatientProfileScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/doctor/patients/:id/edit',
      builder: (_, state) => PatientFormScreen(patientId: state.pathParameters['id']),
    ),

    // ── Patient (role) ────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routePatientDashboard,
      builder: (_, __) => const PatientDashboardScreen(),
    ),

    // ── Admin ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeAdminDashboard,
      builder: (_, __) => const AdminDashboardScreen(),
    ),

    // ── Appointments ──────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeAppointments,
      builder: (_, __) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAppointmentBook,
      builder: (_, __) => const BookAppointmentScreen(),
    ),

    // ── Examinations ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/examinations/:patientId',
      builder: (_, state) => ExaminationsScreen(patientId: state.pathParameters['patientId']!),
    ),

    // ── Vaccinations ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/vaccinations/:patientId',
      builder: (_, state) => VaccinationsScreen(patientId: state.pathParameters['patientId']!),
    ),

    // ── Charts ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/charts/:patientId',
      builder: (_, state) => ChartsScreen(patientId: state.pathParameters['patientId']!),
    ),

    // ── Medications ───────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeMedications,
      builder: (_, __) => const MedicationsScreen(),
    ),

    // ── Messages ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeMessages,
      builder: (_, __) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
          recipientName: extra['recipientName'] as String? ?? '',
        );
      },
    ),

    // ── Safety Tips ───────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeSafetyTips,
      builder: (_, __) => const SafetyTipsScreen(),
    ),

    // ── Failed Operations ─────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeFailedOps,
      builder: (_, __) => const FailedOperationsScreen(),
    ),

    // ── PDF Report ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/pdf-report/:patientId',
      builder: (_, state) => PdfReportScreen(patientId: state.pathParameters['patientId']!),
    ),

    // ── Settings ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeSettings,
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('خطأ')),
    body: Center(child: Text('الصفحة غير موجودة\n${state.error}', textAlign: TextAlign.center)),
  ),
);
