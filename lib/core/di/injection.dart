import 'package:get_it/get_it.dart';
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


final GetIt getIt = GetIt.instance;

Future<void> setupInjection() async {
  final client = Supabase.instance.client;

  // ── Data Sources ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthDataSource>(() => AuthDataSourceImpl(client));
  getIt.registerLazySingleton<PatientDataSource>(() => PatientDataSourceImpl(client));
  getIt.registerLazySingleton<AppointmentDataSource>(() => AppointmentDataSourceImpl(client));
  getIt.registerLazySingleton<ExaminationDataSource>(() => ExaminationDataSourceImpl(client));
  getIt.registerLazySingleton<VaccinationDataSource>(() => VaccinationDataSourceImpl(client));
  getIt.registerLazySingleton<MedicationDataSource>(() => MedicationDataSourceImpl(client));
  getIt.registerLazySingleton<MessageDataSource>(() => MessageDataSourceImpl(client));
  getIt.registerLazySingleton<MediaDataSource>(() => MediaDataSourceImpl(client));
  getIt.registerLazySingleton<DoctorDataSource>(() => DoctorDataSourceImpl(client));
  getIt.registerLazySingleton<SafetyTipsDataSource>(() => SafetyTipsDataSourceImpl(client));

  // ── Repositories ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthDataSource>()));
  getIt.registerLazySingleton<PatientRepository>(
      () => PatientRepositoryImpl(getIt<PatientDataSource>()));
  getIt.registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(getIt<AppointmentDataSource>()));
  getIt.registerLazySingleton<ExaminationRepository>(
      () => ExaminationRepositoryImpl(getIt<ExaminationDataSource>()));
  getIt.registerLazySingleton<VaccinationRepository>(
      () => VaccinationRepositoryImpl(getIt<VaccinationDataSource>()));
  getIt.registerLazySingleton<MedicationRepository>(
      () => MedicationRepositoryImpl(getIt<MedicationDataSource>()));
  getIt.registerLazySingleton<MessageRepository>(
      () => MessageRepositoryImpl(getIt<MessageDataSource>()));
  getIt.registerLazySingleton<MediaRepository>(
      () => MediaRepositoryImpl(getIt<MediaDataSource>()));
  getIt.registerLazySingleton<DoctorRepository>(
      () => DoctorRepositoryImpl(getIt<DoctorDataSource>()));

}