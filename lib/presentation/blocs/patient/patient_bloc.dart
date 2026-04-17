import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/repositories/patient_repository.dart';

abstract class PatientEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadPatients extends PatientEvent {
  final String doctorId; final String? search;
  LoadPatients({required this.doctorId, this.search});
  @override List<Object?> get props => [doctorId, search];
}
class LoadPatientById extends PatientEvent {
  final String id;
  LoadPatientById(this.id);
  @override List<Object?> get props => [id];
}
class CreatePatient extends PatientEvent {
  final PatientModel patient;
  CreatePatient(this.patient);
  @override List<Object?> get props => [patient];
}
class UpdatePatient extends PatientEvent {
  final PatientModel patient;
  UpdatePatient(this.patient);
  @override List<Object?> get props => [patient];
}
class DeletePatient extends PatientEvent {
  final String id;
  DeletePatient(this.id);
  @override List<Object?> get props => [id];
}

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

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository _repo;
  PatientBloc(this._repo) : super(PatientInitial()) {
    on<LoadPatients>(_onLoad);
    on<LoadPatientById>(_onLoadById);
    on<CreatePatient>(_onCreate);
    on<UpdatePatient>(_onUpdate);
    on<DeletePatient>(_onDelete);
  }

  Future<void> _onLoad(LoadPatients e, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      final patients = await _repo.getPatients(doctorId: e.doctorId, search: e.search);
      emit(PatientsLoaded(patients));
    } catch (err) { emit(PatientError(err.toString())); }
  }

  Future<void> _onLoadById(LoadPatientById e, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      final patient = await _repo.getPatientById(e.id);
      emit(PatientLoaded(patient));
    } catch (err) { emit(PatientError(err.toString())); }
  }

  Future<void> _onCreate(CreatePatient e, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await _repo.createPatient(e.patient);
      emit(PatientOperationSuccess('تم إضافة المريض بنجاح'));
    } catch (err) { emit(PatientError(err.toString())); }
  }

  Future<void> _onUpdate(UpdatePatient e, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await _repo.updatePatient(e.patient);
      emit(PatientOperationSuccess('تم تحديث بيانات المريض'));
    } catch (err) { emit(PatientError(err.toString())); }
  }

  Future<void> _onDelete(DeletePatient e, Emitter<PatientState> emit) async {
    emit(PatientLoading());
    try {
      await _repo.deletePatient(e.id);
      emit(PatientOperationSuccess('تم حذف المريض'));
    } catch (err) { emit(PatientError(err.toString())); }
  }
}
