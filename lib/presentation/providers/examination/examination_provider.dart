import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/examination_model.dart';
import '../../../domain/repositories/examination_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class ExaminationState extends Equatable {
  @override List<Object?> get props => [];
}

class ExaminationInitial extends ExaminationState {}
class ExaminationLoading extends ExaminationState {}
class ExaminationsLoaded extends ExaminationState {
  final List<ExaminationModel> examinations;
  ExaminationsLoaded(this.examinations);
  @override List<Object?> get props => [examinations];
}
class GrowthRecordsLoaded extends ExaminationState {
  final List<GrowthRecordModel> records;
  GrowthRecordsLoaded(this.records);
  @override List<Object?> get props => [records];
}
class ExaminationSuccess extends ExaminationState {
  final String message;
  ExaminationSuccess(this.message);
  @override List<Object?> get props => [message];
}
class ExaminationError extends ExaminationState {
  final String message;
  ExaminationError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class ExaminationNotifier extends StateNotifier<ExaminationState> {
  final ExaminationRepository _repo;

  ExaminationNotifier(this._repo) : super(ExaminationInitial());

  Future<void> loadExaminations(String patientId) async {
    state = ExaminationLoading();
    try {
      final list = await _repo.getExaminations(patientId);
      state = ExaminationsLoaded(list);
    } catch (err) {
      state = ExaminationError(err.toString());
    }
  }

  Future<void> addExamination(ExaminationModel examination) async {
    state = ExaminationLoading();
    try {
      await _repo.addExamination(examination);
      state = ExaminationSuccess('تم إضافة الفحص');
    } catch (err) {
      state = ExaminationError(err.toString());
    }
  }

  Future<void> deleteExamination(String id) async {
    state = ExaminationLoading();
    try {
      await _repo.deleteExamination(id);
      state = ExaminationSuccess('تم حذف الفحص');
    } catch (err) {
      state = ExaminationError(err.toString());
    }
  }

  Future<void> loadGrowthRecords(String patientId) async {
    state = ExaminationLoading();
    try {
      final records = await _repo.getGrowthRecords(patientId);
      state = GrowthRecordsLoaded(records);
    } catch (err) {
      state = ExaminationError(err.toString());
    }
  }

  Future<void> addGrowthRecord(GrowthRecordModel record) async {
    state = ExaminationLoading();
    try {
      await _repo.addGrowthRecord(record);
      state = ExaminationSuccess('تم إضافة سجل النمو');
    } catch (err) {
      state = ExaminationError(err.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final examinationProvider = StateNotifierProvider<ExaminationNotifier, ExaminationState>((ref) {
  return ExaminationNotifier(ref.watch(examinationRepositoryProvider));
});
