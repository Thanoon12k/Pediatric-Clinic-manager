import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/appointment_model.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
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

// ─── Notifier ────────────────────────────────────────────────────────────────
class AppointmentNotifier extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repo;

  AppointmentNotifier(this._repo) : super(AppointmentInitial());

  Future<void> loadAppointments({required String doctorId, DateTime? date}) async {
    state = AppointmentLoading();
    try {
      final list = await _repo.getAppointments(doctorId: doctorId, date: date);
      state = AppointmentsLoaded(list);
    } catch (err) {
      state = AppointmentError(err.toString());
    }
  }

  Future<void> loadPatientAppointments(String patientId) async {
    state = AppointmentLoading();
    try {
      final list = await _repo.getPatientAppointments(patientId);
      state = AppointmentsLoaded(list);
    } catch (err) {
      state = AppointmentError(err.toString());
    }
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    state = AppointmentLoading();
    try {
      await _repo.createAppointment(appointment);
      state = AppointmentSuccess('تم حجز الموعد بنجاح');
    } catch (err) {
      state = AppointmentError(err.toString());
    }
  }

  Future<void> updateAppointmentStatus({required String id, required AppointmentStatus status, String? notes}) async {
    state = AppointmentLoading();
    try {
      await _repo.updateAppointmentStatus(id: id, status: status, notes: notes);
      state = AppointmentSuccess('تم تحديث حالة الموعد');
    } catch (err) {
      state = AppointmentError(err.toString());
    }
  }

  Future<void> loadAvailableSlots({required String doctorId, required DateTime date}) async {
    state = AppointmentLoading();
    try {
      final slots = await _repo.getAvailableTimeSlots(doctorId: doctorId, date: date);
      state = SlotsLoaded(slots);
    } catch (err) {
      state = AppointmentError(err.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final appointmentProvider = StateNotifierProvider<AppointmentNotifier, AppointmentState>((ref) {
  return AppointmentNotifier(ref.watch(appointmentRepositoryProvider));
});
