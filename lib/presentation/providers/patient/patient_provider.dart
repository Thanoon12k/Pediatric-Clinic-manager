import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/repositories/patient_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class PatientState extends Equatable {
  @override List<Object?> get props => [];
}

class PatientInitial extends PatientState {}
class PatientLoading extends PatientState {}
class PatientsLoaded extends PatientState {
  final List<PatientModel> patients;
  PatientsLoaded(this.patients);
  @override List<Object?> get props => [patients];
}
class PatientLoaded extends PatientState {
  final PatientModel patient;
  PatientLoaded(this.patient);
  @override List<Object?> get props => [patient];
}
class PatientOperationSuccess extends PatientState {
  final String message;
  PatientOperationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class PatientError extends PatientState {
  final String message;
  PatientError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class PatientNotifier extends StateNotifier<PatientState> {
  final PatientRepository _repo;

  PatientNotifier(this._repo) : super(PatientInitial());

  Future<void> loadPatients({required String doctorId, String? search}) async {
    state = PatientLoading();
    try {
      final patients = await _repo.getPatients(doctorId: doctorId, search: search);
      state = PatientsLoaded(patients);
    } catch (err) {
      state = PatientError(err.toString());
    }
  }

  Future<void> loadPatientById(String id) async {
    state = PatientLoading();
    try {
      final patient = await _repo.getPatientById(id);
      state = PatientLoaded(patient);
    } catch (err) {
      state = PatientError(err.toString());
    }
  }

  Future<void> createPatient(PatientModel patient) async {
    state = PatientLoading();
    try {
      await _repo.createPatient(patient);
      state = PatientOperationSuccess('تم إضافة المريض بنجاح');
    } catch (err) {
      state = PatientError(err.toString());
    }
  }

  Future<void> updatePatient(PatientModel patient) async {
    state = PatientLoading();
    try {
      await _repo.updatePatient(patient);
      state = PatientOperationSuccess('تم تحديث بيانات المريض');
    } catch (err) {
      state = PatientError(err.toString());
    }
  }

  Future<void> deletePatient(String id) async {
    state = PatientLoading();
    try {
      await _repo.deletePatient(id);
      state = PatientOperationSuccess('تم حذف المريض');
    } catch (err) {
      state = PatientError(err.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier(ref.watch(patientRepositoryProvider));
});
