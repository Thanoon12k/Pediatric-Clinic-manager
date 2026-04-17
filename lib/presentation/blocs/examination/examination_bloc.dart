import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/examination_model.dart';
import '../../../domain/repositories/examination_repository.dart';

abstract class ExaminationEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadExaminations extends ExaminationEvent {
  final String patientId;
  LoadExaminations(this.patientId);
  @override List<Object?> get props => [patientId];
}
class AddExamination extends ExaminationEvent {
  final ExaminationModel examination;
  AddExamination(this.examination);
  @override List<Object?> get props => [examination];
}
class DeleteExamination extends ExaminationEvent {
  final String id;
  DeleteExamination(this.id);
  @override List<Object?> get props => [id];
}
class LoadGrowthRecords extends ExaminationEvent {
  final String patientId;
  LoadGrowthRecords(this.patientId);
  @override List<Object?> get props => [patientId];
}
class AddGrowthRecord extends ExaminationEvent {
  final GrowthRecordModel record;
  AddGrowthRecord(this.record);
  @override List<Object?> get props => [record];
}

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
class ExaminationSuccess extends ExaminationState { final String message; ExaminationSuccess(this.message); @override List<Object?> get props => [message]; }
class ExaminationError extends ExaminationState { final String message; ExaminationError(this.message); @override List<Object?> get props => [message]; }

class ExaminationBloc extends Bloc<ExaminationEvent, ExaminationState> {
  final ExaminationRepository _repo;
  ExaminationBloc(this._repo) : super(ExaminationInitial()) {
    on<LoadExaminations>(_onLoad);
    on<AddExamination>(_onAdd);
    on<DeleteExamination>(_onDelete);
    on<LoadGrowthRecords>(_onLoadGrowth);
    on<AddGrowthRecord>(_onAddGrowth);
  }

  Future<void> _onLoad(LoadExaminations e, Emitter<ExaminationState> emit) async {
    emit(ExaminationLoading());
    try { emit(ExaminationsLoaded(await _repo.getExaminations(e.patientId))); }
    catch (err) { emit(ExaminationError(err.toString())); }
  }

  Future<void> _onAdd(AddExamination e, Emitter<ExaminationState> emit) async {
    emit(ExaminationLoading());
    try { await _repo.addExamination(e.examination); emit(ExaminationSuccess('تم إضافة الفحص')); }
    catch (err) { emit(ExaminationError(err.toString())); }
  }

  Future<void> _onDelete(DeleteExamination e, Emitter<ExaminationState> emit) async {
    emit(ExaminationLoading());
    try { await _repo.deleteExamination(e.id); emit(ExaminationSuccess('تم حذف الفحص')); }
    catch (err) { emit(ExaminationError(err.toString())); }
  }

  Future<void> _onLoadGrowth(LoadGrowthRecords e, Emitter<ExaminationState> emit) async {
    emit(ExaminationLoading());
    try { emit(GrowthRecordsLoaded(await _repo.getGrowthRecords(e.patientId))); }
    catch (err) { emit(ExaminationError(err.toString())); }
  }

  Future<void> _onAddGrowth(AddGrowthRecord e, Emitter<ExaminationState> emit) async {
    emit(ExaminationLoading());
    try { await _repo.addGrowthRecord(e.record); emit(ExaminationSuccess('تم إضافة سجل النمو')); }
    catch (err) { emit(ExaminationError(err.toString())); }
  }
}
