import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/doctor_model.dart';
import '../../../domain/repositories/doctor_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class DoctorState extends Equatable {
  @override List<Object?> get props => [];
}

class DoctorInitial extends DoctorState {}
class DoctorLoading extends DoctorState {}
class DoctorsLoaded extends DoctorState {
  final List<DoctorModel> doctors;
  DoctorsLoaded(this.doctors);
  @override List<Object?> get props => [doctors];
}
class DoctorProfileLoaded extends DoctorState {
  final DoctorModel? doctor;
  DoctorProfileLoaded(this.doctor);
  @override List<Object?> get props => [doctor];
}
class DoctorSuccess extends DoctorState {
  final String message;
  DoctorSuccess(this.message);
  @override List<Object?> get props => [message];
}
class DoctorError extends DoctorState {
  final String message;
  DoctorError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class DoctorNotifier extends StateNotifier<DoctorState> {
  final DoctorRepository _repo;

  DoctorNotifier(this._repo) : super(DoctorInitial());

  Future<void> loadDoctors() async {
    state = DoctorLoading();
    try {
      final list = await _repo.getAllDoctors();
      state = DoctorsLoaded(list);
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> loadDoctorByUserId(String userId) async {
    state = DoctorLoading();
    try {
      final doc = await _repo.getDoctorByUserId(userId);
      state = DoctorProfileLoaded(doc);
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> loadDoctorById(String id) async {
    state = DoctorLoading();
    try {
      final doc = await _repo.getDoctorById(id);
      state = DoctorProfileLoaded(doc);
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> createDoctor(DoctorModel doc) async {
    state = DoctorLoading();
    try {
      await _repo.createDoctor(doc);
      state = DoctorSuccess('تم إنشاء الملف الشخصي');
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> updateDoctor(DoctorModel doc) async {
    state = DoctorLoading();
    try {
      await _repo.updateDoctor(doc);
      state = DoctorSuccess('تم تحديث الملف الشخصي');
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> deleteDoctor(String id) async {
    state = DoctorLoading();
    try {
      await _repo.deleteDoctor(id);
      state = DoctorSuccess('تم حذف الطبيب');
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }

  Future<void> toggleDoctorStatus({required String id, required bool isActive}) async {
    state = DoctorLoading();
    try {
      await _repo.toggleDoctorStatus(id: id, isActive: isActive);
      state = DoctorSuccess(isActive ? 'تم تفعيل الطبيب' : 'تم إيقاف الطبيب');
    } catch (e) {
      state = DoctorError(e.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  return DoctorNotifier(ref.watch(doctorRepositoryProvider));
});
