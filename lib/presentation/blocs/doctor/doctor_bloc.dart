import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/doctor_model.dart';
import '../../../domain/repositories/doctor_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class DoctorEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadDoctors          extends DoctorEvent {}
class LoadDoctorByUserId   extends DoctorEvent { final String userId;   LoadDoctorByUserId(this.userId);   @override List<Object?> get props => [userId]; }
class LoadDoctorById       extends DoctorEvent { final String id;       LoadDoctorById(this.id);           @override List<Object?> get props => [id]; }
class CreateDoctor         extends DoctorEvent { final DoctorModel doc; CreateDoctor(this.doc);             @override List<Object?> get props => [doc]; }
class UpdateDoctor         extends DoctorEvent { final DoctorModel doc; UpdateDoctor(this.doc);             @override List<Object?> get props => [doc]; }
class DeleteDoctor         extends DoctorEvent { final String id;       DeleteDoctor(this.id);              @override List<Object?> get props => [id]; }
class ToggleDoctorStatus   extends DoctorEvent {
  final String id; final bool isActive;
  ToggleDoctorStatus({required this.id, required this.isActive});
  @override List<Object?> get props => [id, isActive];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class DoctorState extends Equatable {
  @override List<Object?> get props => [];
}
class DoctorInitial        extends DoctorState {}
class DoctorLoading        extends DoctorState {}
class DoctorsLoaded        extends DoctorState { final List<DoctorModel> doctors; DoctorsLoaded(this.doctors); @override List<Object?> get props => [doctors]; }
class DoctorProfileLoaded  extends DoctorState { final DoctorModel? doctor; DoctorProfileLoaded(this.doctor); @override List<Object?> get props => [doctor]; }
class DoctorSuccess        extends DoctorState { final String message; DoctorSuccess(this.message); @override List<Object?> get props => [message]; }
class DoctorError          extends DoctorState { final String message; DoctorError(this.message); @override List<Object?> get props => [message]; }

// ─── BLoC ─────────────────────────────────────────────────────────────────────
class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository _repo;
  DoctorBloc(this._repo) : super(DoctorInitial()) {
    on<LoadDoctors>((event, emit) async {
      emit(DoctorLoading());
      try { emit(DoctorsLoaded(await _repo.getAllDoctors())); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<LoadDoctorByUserId>((event, emit) async {
      emit(DoctorLoading());
      try { emit(DoctorProfileLoaded(await _repo.getDoctorByUserId(event.userId))); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<LoadDoctorById>((event, emit) async {
      emit(DoctorLoading());
      try { emit(DoctorProfileLoaded(await _repo.getDoctorById(event.id))); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<CreateDoctor>((event, emit) async {
      emit(DoctorLoading());
      try { await _repo.createDoctor(event.doc); emit(DoctorSuccess('تم إنشاء الملف الشخصي')); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<UpdateDoctor>((event, emit) async {
      emit(DoctorLoading());
      try { await _repo.updateDoctor(event.doc); emit(DoctorSuccess('تم تحديث الملف الشخصي')); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<DeleteDoctor>((event, emit) async {
      emit(DoctorLoading());
      try { await _repo.deleteDoctor(event.id); emit(DoctorSuccess('تم حذف الطبيب')); }
      catch (e) { emit(DoctorError(e.toString())); }
    });

    on<ToggleDoctorStatus>((event, emit) async {
      emit(DoctorLoading());
      try {
        await _repo.toggleDoctorStatus(id: event.id, isActive: event.isActive);
        emit(DoctorSuccess(event.isActive ? 'تم تفعيل الطبيب' : 'تم إيقاف الطبيب'));
      } catch (e) { emit(DoctorError(e.toString())); }
    });
  }
}
