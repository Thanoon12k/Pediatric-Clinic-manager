import 'package:flutter_test/flutter_test.dart';
import 'package:yadati/data/models/user_model.dart';
import 'package:yadati/core/constants/app_constants.dart';

void main() {
  group('Secretary least-privilege role', () {
    test('reads secretary from server-controlled profile.role', () {
      final user = UserModel.fromJson({
        'id': 'secretary-account',
        'email': 'desk@example.test',
        'full_name': 'سكرتير',
        'role': 'secretary',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(user.role, UserRole.secretary);
      expect(user.toJson()['role'], 'secretary');
    });

    test('unknown roles do not become privileged', () {
      final user = UserModel.fromJson({
        'id': 'unknown',
        'email': 'someone@example.test',
        'full_name': 'Test',
        'role': 'super_secretary',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(user.role, UserRole.patient);
    });

    test('clinic queue has a separate protected navigation route', () {
      expect(AppConstants.routeClinicQueue, '/clinic/queue');
    });
  });
}
