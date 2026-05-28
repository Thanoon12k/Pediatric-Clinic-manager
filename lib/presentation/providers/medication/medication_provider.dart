import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/medication_model.dart';
import '../../../domain/repositories/medication_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class MedicationState extends Equatable {
  @override List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}
class MedicationLoading extends MedicationState {}
class MedicationsLoaded extends MedicationState {
  final List<MedicationModel> medications;
  MedicationsLoaded(this.medications);
  @override List<Object?> get props => [medications];
}
class MedicationSuccess extends MedicationState {
  final String message;
  MedicationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class MedicationError extends MedicationState {
  final String message;
  MedicationError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class MedicationNotifier extends StateNotifier<MedicationState> {
  final MedicationRepository _repo;

  MedicationNotifier(this._repo) : super(MedicationInitial());

  Future<void> loadMedications(String doctorId) async {
    state = MedicationLoading();
    try {
      final meds = await _repo.getMedications(doctorId);
      state = MedicationsLoaded(meds);
    } catch (e) {
      state = MedicationError(e.toString());
    }
  }

  Future<void> addMedication(MedicationModel med) async {
    state = MedicationLoading();
    try {
      await _repo.addMedication(med);
      state = MedicationSuccess('تمت إضافة الدواء بنجاح');
    } catch (e) {
      state = MedicationError(e.toString());
    }
  }

  Future<void> updateMedication(MedicationModel med) async {
    state = MedicationLoading();
    try {
      await _repo.updateMedication(med);
      state = MedicationSuccess('تم تعديل الدواء بنجاح');
    } catch (e) {
      state = MedicationError(e.toString());
    }
  }

  Future<void> deleteMedication(String id) async {
    state = MedicationLoading();
    try {
      await _repo.deleteMedication(id);
      state = MedicationSuccess('تم حذف الدواء');
    } catch (e) {
      state = MedicationError(e.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final medicationProvider = StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier(ref.watch(medicationRepositoryProvider));
});
