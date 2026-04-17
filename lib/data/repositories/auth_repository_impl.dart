import '../../data/datasources/auth_datasource.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _ds;
  AuthRepositoryImpl(this._ds);

  @override Future<UserModel?> getCurrentUser() => _ds.getCurrentUser();
  @override Future<UserModel> signIn({required String email, required String password}) =>
      _ds.signIn(email: email, password: password);

  @override Future<UserModel> signUp({required String email, required String password,
    required String fullName, String role = 'patient'}) {
    final userRole = UserRole.values.firstWhere((r) => r.name == role, orElse: () => UserRole.patient);
    return _ds.signUp(email: email, password: password, fullName: fullName, role: userRole);
  }

  @override Future<void> signOut() => _ds.signOut();
  @override Future<void> sendPasswordResetEmail(String email) => _ds.sendPasswordResetEmail(email);
  @override Stream<UserModel?> get authStateChanges => _ds.authStateChanges;
}
