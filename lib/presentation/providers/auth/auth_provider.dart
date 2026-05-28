import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/di/providers.dart';

// ─── States ──────────────────────────────────────────────────────────────────
abstract class AuthBlocState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthBlocState {}
class AuthLoading extends AuthBlocState {}
class AuthAuthenticated extends AuthBlocState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthBlocState {}
class AuthError extends AuthBlocState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class AuthPasswordResetSent extends AuthBlocState {}
class AuthRegistrationSuccess extends AuthBlocState {}

// ─── Notifier ────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthBlocState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial());

  Future<void> checkAuth() async {
    state = AuthLoading();
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (_) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = AuthLoading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'patient',
  }) async {
    state = AuthLoading();
    try {
      await _repo.signUp(email: email, password: password, fullName: fullName, role: role);
      state = AuthRegistrationSuccess();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = AuthLoading();
    try {
      final user = await _repo.signUp(email: email, password: password, fullName: fullName, role: 'patient');
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = AuthUnauthenticated();
  }

  Future<void> sendPasswordReset(String email) async {
    state = AuthLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = AuthPasswordResetSent();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = AuthLoading();
    try {
      await _repo.updatePassword(newPassword);
      state = AuthPasswordResetSent(); // reuse "done" state — screen will navigate away
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthBlocState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
