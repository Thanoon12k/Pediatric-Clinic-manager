import 'package:flutter_test/flutter_test.dart';
import 'package:yadati/data/models/appointment_model.dart';

void main() {
  group('AppointmentModel', () {
    final testJson = {
      'id': 'a1',
      'patient_id': 'p1',
      'doctor_id': 'd1',
      'patient_name': 'أحمد محمد',
      'appointment_date': '2026-05-01',
      'appointment_time': '09:00',
      'status': 'pending',
      'created_at': '2026-04-01T00:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final appt = AppointmentModel.fromJson(testJson);
      expect(appt.id, 'a1');
      expect(appt.status, AppointmentStatus.pending);
      expect(appt.appointmentTime, '09:00');
    });

    test('status confirmed', () {
      final json = Map<String, dynamic>.from(testJson)..['status'] = 'confirmed';
      expect(AppointmentModel.fromJson(json).status, AppointmentStatus.confirmed);
    });

    test('status cancelled', () {
      final json = Map<String, dynamic>.from(testJson)..['status'] = 'cancelled';
      expect(AppointmentModel.fromJson(json).status, AppointmentStatus.cancelled);
    });

    test('toJson produces correct date format', () {
      final appt = AppointmentModel.fromJson(testJson);
      final json = appt.toJson();
      expect(json['appointment_date'], '2026-05-01');
      expect(json['status'], 'pending');
    });
  });
}
