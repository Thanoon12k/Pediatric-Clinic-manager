import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Sources
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/patient_datasource.dart';
import '../../data/datasources/appointment_datasource.dart';
import '../../data/datasources/examination_datasource.dart';
import '../../data/datasources/vaccination_datasource.dart';
import '../../data/datasources/medication_datasource.dart';
import '../../data/datasources/message_datasource.dart';
import '../../data/datasources/media_datasource.dart';
import '../../data/datasources/doctor_datasource.dart';
import '../../data/datasources/safety_tips_datasource.dart';

// Repository Implementations
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../data/repositories/examination_repository_impl.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../data/repositories/doctor_repository_impl.dart';

// Domain Repository Interfaces
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/repositories/examination_repository.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/repositories/doctor_repository.dart';

// ── Supabase Client Provider ─────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Data Sources Providers ───────────────────────────────────────────────────
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDataSourceImpl(ref.watch(supabaseClientProvider));
});

final patientDataSourceProvider = Provider<PatientDataSource>((ref) {
  return PatientDataSourceImpl(ref.watch(supabaseClientProvider));
});

final appointmentDataSourceProvider = Provider<AppointmentDataSource>((ref) {
  return AppointmentDataSourceImpl(ref.watch(supabaseClientProvider));
});

final examinationDataSourceProvider = Provider<ExaminationDataSource>((ref) {
  return ExaminationDataSourceImpl(ref.watch(supabaseClientProvider));
});

final vaccinationDataSourceProvider = Provider<VaccinationDataSource>((ref) {
  return VaccinationDataSourceImpl(ref.watch(supabaseClientProvider));
});

final medicationDataSourceProvider = Provider<MedicationDataSource>((ref) {
  return MedicationDataSourceImpl(ref.watch(supabaseClientProvider));
});

final messageDataSourceProvider = Provider<MessageDataSource>((ref) {
  return MessageDataSourceImpl(ref.watch(supabaseClientProvider));
});

final mediaDataSourceProvider = Provider<MediaDataSource>((ref) {
  return MediaDataSourceImpl(ref.watch(supabaseClientProvider));
});

final doctorDataSourceProvider = Provider<DoctorDataSource>((ref) {
  return DoctorDataSourceImpl(ref.watch(supabaseClientProvider));
});

final safetyTipsDataSourceProvider = Provider<SafetyTipsDataSource>((ref) {
  return SafetyTipsDataSourceImpl(ref.watch(supabaseClientProvider));
});

// ── Repositories Providers ───────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(ref.watch(patientDataSourceProvider));
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl(ref.watch(appointmentDataSourceProvider));
});

final examinationRepositoryProvider = Provider<ExaminationRepository>((ref) {
  return ExaminationRepositoryImpl(ref.watch(examinationDataSourceProvider));
});

final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) {
  return VaccinationRepositoryImpl(ref.watch(vaccinationDataSourceProvider));
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(medicationDataSourceProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.watch(messageDataSourceProvider));
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(ref.watch(mediaDataSourceProvider));
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepositoryImpl(ref.watch(doctorDataSourceProvider));
});
