import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/vaccination_model.dart';
import '../../../domain/repositories/vaccination_repository.dart';

abstract class VaccinationEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadVaccinations extends VaccinationEvent { final String patientId; LoadVaccinations(this.patientId); @override List<Object?> get props => [patientId]; }
class AddVaccination extends VaccinationEvent { final VaccinationModel vaccination; AddVaccination(this.vaccination); @override List<Object?> get props => [vaccination]; }
class UpdateVaccination extends VaccinationEvent { final VaccinationModel vaccination; UpdateVaccination(this.vaccination); @override List<Object?> get props => [vaccination]; }
class DeleteVaccination extends VaccinationEvent { final String id; DeleteVaccination(this.id); @override List<Object?> get props => [id]; }

abstract class VaccinationState extends Equatable {
  @override List<Object?> get props => [];
}
class VaccinationInitial extends VaccinationState {}
class VaccinationLoading extends VaccinationState {}
class VaccinationsLoaded extends VaccinationState { final List<VaccinationModel> vaccinations; VaccinationsLoaded(this.vaccinations); @override List<Object?> get props => [vaccinations]; }
class VaccinationSuccess extends VaccinationState { final String message; VaccinationSuccess(this.message); @override List<Object?> get props => [message]; }
class VaccinationError extends VaccinationState { final String message; VaccinationError(this.message); @override List<Object?> get props => [message]; }

class VaccinationBloc extends Bloc<VaccinationEvent, VaccinationState> {
  final VaccinationRepository _repo;
  VaccinationBloc(this._repo) : super(VaccinationInitial()) {
    on<LoadVaccinations>((e, emit) async {
      emit(VaccinationLoading());
      try { emit(VaccinationsLoaded(await _repo.getVaccinations(e.patientId))); }
      catch (err) { emit(VaccinationError(err.toString())); }
    });
    on<AddVaccination>((e, emit) async {
      emit(VaccinationLoading());
      try { await _repo.addVaccination(e.vaccination); emit(VaccinationSuccess('تم إضافة التحصين')); }
      catch (err) { emit(VaccinationError(err.toString())); }
    });
    on<UpdateVaccination>((e, emit) async {
      emit(VaccinationLoading());
      try { await _repo.updateVaccination(e.vaccination); emit(VaccinationSuccess('تم تحديث التحصين')); }
      catch (err) { emit(VaccinationError(err.toString())); }
    });
    on<DeleteVaccination>((e, emit) async {
      emit(VaccinationLoading());
      try { await _repo.deleteVaccination(e.id); emit(VaccinationSuccess('تم حذف التحصين')); }
      catch (err) { emit(VaccinationError(err.toString())); }
    });
  }
}
