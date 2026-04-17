import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/patient/patient_bloc.dart';
import '../../presentation/blocs/appointment/appointment_bloc.dart';
import '../../presentation/blocs/examination/examination_bloc.dart';
import '../../presentation/blocs/vaccination/vaccination_bloc.dart';
import '../../presentation/blocs/medication/medication_bloc.dart';
import '../../presentation/blocs/message/message_bloc.dart';
import '../../presentation/blocs/doctor/doctor_bloc.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
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

/// Wraps a screen with all needed BlocProviders
Widget _withBlocs(Widget child, {bool needsPatient = false, bool needsDoctor = false,
    bool needsAppointment = false, bool needsExam = false, bool needsVaccine = false,
    bool needsMed = false, bool needsMsg = false}) {
  final providers = <BlocProvider>[
    BlocProvider.value(value: getIt<AuthBloc>()..add(AuthCheckRequested())),
    if (needsDoctor) BlocProvider(create: (_) => getIt<DoctorBloc>()),
    if (needsPatient) BlocProvider(create: (_) => getIt<PatientBloc>()),
    if (needsAppointment) BlocProvider(create: (_) => getIt<AppointmentBloc>()),
    if (needsExam) BlocProvider(create: (_) => getIt<ExaminationBloc>()),
    if (needsVaccine) BlocProvider(create: (_) => getIt<VaccinationBloc>()),
    if (needsMed) BlocProvider(create: (_) => getIt<MedicationBloc>()),
    if (needsMsg) BlocProvider(create: (_) => getIt<MessageBloc>()),
  ];
  return MultiBlocProvider(providers: providers, child: child);
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (_, __) => _withBlocs(const SplashScreen()),
    ),
    GoRoute(
      path: AppConstants.routeWelcome,
      builder: (_, __) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      builder: (_, __) => BlocProvider(create: (_) => getIt<AuthBloc>(), child: const LoginScreen()),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      builder: (_, __) => BlocProvider(create: (_) => getIt<AuthBloc>(), child: const RegisterScreen()),
    ),
    GoRoute(
      path: AppConstants.routeForgotPassword,
      builder: (_, __) => BlocProvider(create: (_) => getIt<AuthBloc>(), child: const ForgotPasswordScreen()),
    ),

    // ── Doctor ────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeDoctorDashboard,
      builder: (_, __) => _withBlocs(const DoctorDashboardScreen(),
          needsDoctor: true, needsPatient: true, needsAppointment: true, needsMsg: true),
    ),
    GoRoute(
      path: AppConstants.routeDoctorProfile,
      builder: (_, __) => BlocProvider(create: (_) => getIt<DoctorBloc>(), child: const DoctorProfileScreen()),
    ),

    // ── Patients ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routePatientList,
      builder: (_, __) => BlocProvider(create: (_) => getIt<PatientBloc>(), child: const PatientListScreen()),
    ),
    GoRoute(
      path: '/doctor/patients/add',
      builder: (_, __) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<PatientBloc>()),
        BlocProvider(create: (_) => getIt<DoctorBloc>()),
      ], child: const PatientFormScreen()),
    ),
    GoRoute(
      path: '/doctor/patients/:id',
      builder: (_, state) => BlocProvider(
        create: (_) => getIt<PatientBloc>(),
        child: PatientProfileScreen(patientId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/doctor/patients/:id/edit',
      builder: (_, state) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<PatientBloc>()),
        BlocProvider(create: (_) => getIt<DoctorBloc>()),
      ], child: PatientFormScreen(patientId: state.pathParameters['id'])),
    ),

    // ── Patient (role) ────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routePatientDashboard,
      builder: (_, __) => _withBlocs(const PatientDashboardScreen()),
    ),

    // ── Admin ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeAdminDashboard,
      builder: (_, __) => BlocProvider(create: (_) => getIt<DoctorBloc>(), child: const AdminDashboardScreen()),
    ),

    // ── Appointments ──────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeAppointments,
      builder: (_, __) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<AppointmentBloc>()),
        BlocProvider(create: (_) => getIt<DoctorBloc>()),
      ], child: const AppointmentsScreen()),
    ),
    GoRoute(
      path: AppConstants.routeAppointmentBook,
      builder: (_, __) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<AppointmentBloc>()),
        BlocProvider(create: (_) => getIt<DoctorBloc>()),
      ], child: const BookAppointmentScreen()),
    ),

    // ── Examinations ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/examinations/:patientId',
      builder: (_, state) => BlocProvider(
        create: (_) => getIt<ExaminationBloc>(),
        child: ExaminationsScreen(patientId: state.pathParameters['patientId']!),
      ),
    ),

    // ── Vaccinations ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/vaccinations/:patientId',
      builder: (_, state) => BlocProvider(
        create: (_) => getIt<VaccinationBloc>(),
        child: VaccinationsScreen(patientId: state.pathParameters['patientId']!),
      ),
    ),

    // ── Charts ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/charts/:patientId',
      builder: (_, state) => BlocProvider(
        create: (_) => getIt<ExaminationBloc>(),
        child: ChartsScreen(patientId: state.pathParameters['patientId']!),
      ),
    ),

    // ── Medications ───────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeMedications,
      builder: (_, __) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<MedicationBloc>()),
        BlocProvider(create: (_) => getIt<DoctorBloc>()),
      ], child: const MedicationsScreen()),
    ),

    // ── Messages ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeMessages,
      builder: (_, __) => BlocProvider(create: (_) => getIt<MessageBloc>(), child: const MessagesScreen()),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BlocProvider(
          create: (_) => getIt<MessageBloc>(),
          child: ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
            recipientName: extra['recipientName'] as String? ?? '',
          ),
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
      builder: (_, state) => BlocProvider(
        create: (_) => getIt<PatientBloc>(),
        child: PdfReportScreen(patientId: state.pathParameters['patientId']!),
      ),
    ),

    // ── Settings ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppConstants.routeSettings,
      builder: (_, __) => BlocProvider(create: (_) => getIt<AuthBloc>(), child: const SettingsScreen()),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('خطأ')),
    body: Center(child: Text('الصفحة غير موجودة\n${state.error}', textAlign: TextAlign.center)),
  ),
);
