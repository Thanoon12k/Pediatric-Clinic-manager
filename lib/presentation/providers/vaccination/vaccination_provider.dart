import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/vaccination_model.dart';
import '../../../domain/repositories/vaccination_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class VaccinationState extends Equatable {
  @override List<Object?> get props => [];
}

class VaccinationInitial extends VaccinationState {}
class VaccinationLoading extends VaccinationState {}
class VaccinationsLoaded extends VaccinationState {
  final List<VaccinationModel> vaccinations;
  VaccinationsLoaded(this.vaccinations);
  @override List<Object?> get props => [vaccinations];
}
class VaccinationSuccess extends VaccinationState {
  final String message;
  VaccinationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class VaccinationError extends VaccinationState {
  final String message;
  VaccinationError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class VaccinationNotifier extends StateNotifier<VaccinationState> {
  final VaccinationRepository _repo;

  VaccinationNotifier(this._repo) : super(VaccinationInitial());

  Future<void> loadVaccinations(String patientId) async {
    state = VaccinationLoading();
    try {
      final list = await _repo.getVaccinations(patientId);
      state = VaccinationsLoaded(list);
    } catch (err) {
      state = VaccinationError(err.toString());
    }
  }

  Future<void> addVaccination(VaccinationModel vaccination) async {
    state = VaccinationLoading();
    try {
      await _repo.addVaccination(vaccination);
      state = VaccinationSuccess('تم إضافة التحصين');
    } catch (err) {
      state = VaccinationError(err.toString());
    }
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    state = VaccinationLoading();
    try {
      await _repo.updateVaccination(vaccination);
      state = VaccinationSuccess('تم تحديث التحصين');
    } catch (err) {
      state = VaccinationError(err.toString());
    }
  }

  Future<void> deleteVaccination(String id) async {
    state = VaccinationLoading();
    try {
      await _repo.deleteVaccination(id);
      state = VaccinationSuccess('تم حذف التحصين');
    } catch (err) {
      state = VaccinationError(err.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final vaccinationProvider = StateNotifierProvider<VaccinationNotifier, VaccinationState>((ref) {
  return VaccinationNotifier(ref.watch(vaccinationRepositoryProvider));
});
