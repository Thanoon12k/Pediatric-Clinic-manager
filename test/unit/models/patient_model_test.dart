import 'package:flutter_test/flutter_test.dart';
import 'package:yadati/data/models/patient_model.dart';

void main() {
  group('PatientModel', () {
    final testJson = {
      'id': 'p1',
      'doctor_id': 'd1',
      'full_name': 'أحمد محمد',
      'date_of_birth': '2020-06-15',
      'gender': 'male',
      'blood_type': 'A+',
      'weight': 15.5,
      'height': 90.0,
      'guardian_name': 'محمد أحمد',
      'guardian_phone': '+9647701234567',
      'treatment_status': 'under_treatment',
      'allow_chat': true,
      'allow_photos': true,
      'allow_voice': true,
      'allow_messages': true,
      'created_at': '2024-01-01T00:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final patient = PatientModel.fromJson(testJson);
      expect(patient.id, 'p1');
      expect(patient.fullName, 'أحمد محمد');
      expect(patient.gender, Gender.male);
      expect(patient.bloodType, 'A+');
      expect(patient.treatmentStatus, TreatmentStatus.underTreatment);
    });

    test('toJson produces correct keys', () {
      final patient = PatientModel.fromJson(testJson);
      final json = patient.toJson();
      expect(json['full_name'], 'أحمد محمد');
      expect(json['treatment_status'], 'under_treatment');
      expect(json['gender'], 'male');
    });

    test('ageDisplay returns correct string for a toddler', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 2 + 10));
      final json = Map<String, dynamic>.from(testJson)
        ..['date_of_birth'] = '${dob.year}-${dob.month.toString().padLeft(2,'0')}-${dob.day.toString().padLeft(2,'0')}';
      final patient = PatientModel.fromJson(json);
      expect(patient.ageDisplay, contains('سنت'));
    });

    test('gender parses female correctly', () {
      final json = Map<String, dynamic>.from(testJson)..['gender'] = 'female';
      final patient = PatientModel.fromJson(json);
      expect(patient.gender, Gender.female);
    });

    test('treatmentStatus recovered', () {
      final json = Map<String, dynamic>.from(testJson)..['treatment_status'] = 'recovered';
      final patient = PatientModel.fromJson(json);
      expect(patient.treatmentStatus, TreatmentStatus.recovered);
    });

    test('copyWith preserves unchanged fields', () {
      final original = PatientModel.fromJson(testJson);
      final copy = original.copyWith(treatmentStatus: TreatmentStatus.recovered);
      expect(copy.id, original.id);
      expect(copy.fullName, original.fullName);
      expect(copy.treatmentStatus, TreatmentStatus.recovered);
    });
  });
}
