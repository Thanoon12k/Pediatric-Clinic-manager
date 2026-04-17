import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/medication_model.dart';
import '../../../domain/repositories/medication_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class MedicationEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadMedications  extends MedicationEvent { final String doctorId; LoadMedications(this.doctorId); @override List<Object?> get props => [doctorId]; }
class AddMedication    extends MedicationEvent { final MedicationModel med; AddMedication(this.med); @override List<Object?> get props => [med]; }
class UpdateMedication extends MedicationEvent { final MedicationModel med; UpdateMedication(this.med); @override List<Object?> get props => [med]; }
class DeleteMedication extends MedicationEvent { final String id; DeleteMedication(this.id); @override List<Object?> get props => [id]; }

// ─── States ───────────────────────────────────────────────────────────────────
abstract class MedicationState extends Equatable {
  @override List<Object?> get props => [];
}
class MedicationInitial   extends MedicationState {}
class MedicationLoading   extends MedicationState {}
class MedicationsLoaded   extends MedicationState { final List<MedicationModel> medications; MedicationsLoaded(this.medications); @override List<Object?> get props => [medications]; }
class MedicationSuccess   extends MedicationState { final String message; MedicationSuccess(this.message); @override List<Object?> get props => [message]; }
class MedicationError     extends MedicationState { final String message; MedicationError(this.message); @override List<Object?> get props => [message]; }

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _repo;
  MedicationBloc(this._repo) : super(MedicationInitial()) {
    on<LoadMedications>((event, emit) async {
      emit(MedicationLoading());
      try {
        final meds = await _repo.getMedications(event.doctorId);
        emit(MedicationsLoaded(meds));
      } catch (e) { emit(MedicationError(e.toString())); }
    });

    on<AddMedication>((event, emit) async {
      emit(MedicationLoading());
      try {
        await _repo.addMedication(event.med);
        emit(MedicationSuccess('تمت إضافة الدواء بنجاح'));
      } catch (e) { emit(MedicationError(e.toString())); }
    });

    on<UpdateMedication>((event, emit) async {
      emit(MedicationLoading());
      try {
        await _repo.updateMedication(event.med);
        emit(MedicationSuccess('تم تعديل الدواء بنجاح'));
      } catch (e) { emit(MedicationError(e.toString())); }
    });

    on<DeleteMedication>((event, emit) async {
      emit(MedicationLoading());
      try {
        await _repo.deleteMedication(event.id);
        emit(MedicationSuccess('تم حذف الدواء'));
      } catch (e) { emit(MedicationError(e.toString())); }
    });
  }
}
