import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/appointment_model.dart';
import '../../../domain/repositories/appointment_repository.dart';

abstract class AppointmentEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadAppointments extends AppointmentEvent {
  final String doctorId; final DateTime? date;
  LoadAppointments({required this.doctorId, this.date});
  @override List<Object?> get props => [doctorId, date];
}
class LoadPatientAppointments extends AppointmentEvent {
  final String patientId;
  LoadPatientAppointments(this.patientId);
  @override List<Object?> get props => [patientId];
}
class BookAppointment extends AppointmentEvent {
  final AppointmentModel appointment;
  BookAppointment(this.appointment);
  @override List<Object?> get props => [appointment];
}
class UpdateAppointmentStatus extends AppointmentEvent {
  final String id; final AppointmentStatus status; final String? notes;
  UpdateAppointmentStatus({required this.id, required this.status, this.notes});
  @override List<Object?> get props => [id, status];
}
class LoadAvailableSlots extends AppointmentEvent {
  final String doctorId; final DateTime date;
  LoadAvailableSlots({required this.doctorId, required this.date});
  @override List<Object?> get props => [doctorId, date];
}

abstract class AppointmentState extends Equatable {
  @override List<Object?> get props => [];
}
class AppointmentInitial extends AppointmentState {}
class AppointmentLoading extends AppointmentState {}
class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentModel> appointments;
  AppointmentsLoaded(this.appointments);
  @override List<Object?> get props => [appointments];
}
class SlotsLoaded extends AppointmentState {
  final List<String> slots;
  SlotsLoaded(this.slots);
  @override List<Object?> get props => [slots];
}
class AppointmentSuccess extends AppointmentState {
  final String message;
  AppointmentSuccess(this.message);
  @override List<Object?> get props => [message];
}
class AppointmentError extends AppointmentState {
  final String message;
  AppointmentError(this.message);
  @override List<Object?> get props => [message];
}

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository _repo;
  AppointmentBloc(this._repo) : super(AppointmentInitial()) {
    on<LoadAppointments>(_onLoad);
    on<LoadPatientAppointments>(_onLoadPatient);
    on<BookAppointment>(_onBook);
    on<UpdateAppointmentStatus>(_onUpdateStatus);
    on<LoadAvailableSlots>(_onLoadSlots);
  }

  Future<void> _onLoad(LoadAppointments e, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    try {
      final list = await _repo.getAppointments(doctorId: e.doctorId, date: e.date);
      emit(AppointmentsLoaded(list));
    } catch (err) { emit(AppointmentError(err.toString())); }
  }

  Future<void> _onLoadPatient(LoadPatientAppointments e, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    try {
      final list = await _repo.getPatientAppointments(e.patientId);
      emit(AppointmentsLoaded(list));
    } catch (err) { emit(AppointmentError(err.toString())); }
  }

  Future<void> _onBook(BookAppointment e, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    try {
      await _repo.createAppointment(e.appointment);
      emit(AppointmentSuccess('تم حجز الموعد بنجاح'));
    } catch (err) { emit(AppointmentError(err.toString())); }
  }

  Future<void> _onUpdateStatus(UpdateAppointmentStatus e, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    try {
      await _repo.updateAppointmentStatus(id: e.id, status: e.status, notes: e.notes);
      emit(AppointmentSuccess('تم تحديث حالة الموعد'));
    } catch (err) { emit(AppointmentError(err.toString())); }
  }

  Future<void> _onLoadSlots(LoadAvailableSlots e, Emitter<AppointmentState> emit) async {
    emit(AppointmentLoading());
    try {
      final slots = await _repo.getAvailableTimeSlots(doctorId: e.doctorId, date: e.date);
      emit(SlotsLoaded(slots));
    } catch (err) { emit(AppointmentError(err.toString())); }
  }
}
