import 'package:flutter_test/flutter_test.dart';
import 'package:yadati/data/models/vaccination_model.dart';

void main() {
  group('VaccinationModel', () {
    final testJson = {
      'id': 'v1',
      'patient_id': 'p1',
      'doctor_id': 'd1',
      'vaccine_name': 'BCG',
      'status': 'given',
      'dose_number': 1,
      'date_given': '2024-03-01',
      'created_at': '2024-03-01T00:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final vac = VaccinationModel.fromJson(testJson);
      expect(vac.vaccineName, 'BCG');
      expect(vac.status, VaccinationStatus.given);
      expect(vac.doseNumber, 1);
    });

    test('due status parsed', () {
      final json = Map<String, dynamic>.from(testJson)..['status'] = 'due';
      expect(VaccinationModel.fromJson(json).status, VaccinationStatus.due);
    });

    test('overdue status parsed', () {
      final json = Map<String, dynamic>.from(testJson)..['status'] = 'overdue';
      expect(VaccinationModel.fromJson(json).status, VaccinationStatus.overdue);
    });

    test('toJson date format', () {
      final vac = VaccinationModel.fromJson(testJson);
      final json = vac.toJson();
      expect(json['date_given'], '2024-03-01');
      expect(json['vaccine_name'], 'BCG');
    });
  });
}
