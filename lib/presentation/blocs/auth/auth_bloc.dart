import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

// ─── Events ─────────────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}
class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email, password;
  AuthLoginRequested({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}
// Alias used in register screen
class AuthRegisterRequested extends AuthEvent {
  final String email, password, fullName, role;
  AuthRegisterRequested({required this.email, required this.password, required this.fullName, this.role = 'patient'});
  @override List<Object?> get props => [email, password, fullName, role];
}
class AuthSignUpRequested extends AuthEvent {
  final String email, password, fullName;
  final String? phone;
  AuthSignUpRequested({required this.email, required this.password, required this.fullName, this.phone});
  @override List<Object?> get props => [email, password, fullName];
}
class AuthLogoutRequested extends AuthEvent {}
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  AuthPasswordResetRequested(this.email);
  @override List<Object?> get props => [email];
}
// Alias used in forgot password screen
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  AuthForgotPasswordRequested({required this.email});
  @override List<Object?> get props => [email];
}

// ─── States ──────────────────────────────────────────────────────────────────
abstract class AuthBlocState extends Equatable {
  @override List<Object?> get props => [];
}
class AuthInitial          extends AuthBlocState {}
class AuthLoading          extends AuthBlocState {}
class AuthAuthenticated    extends AuthBlocState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}
class AuthUnauthenticated  extends AuthBlocState {}
class AuthError            extends AuthBlocState {
  final String message;
  AuthError(this.message);
  @override List<Object?> get props => [message];
}
class AuthPasswordResetSent    extends AuthBlocState {}
class AuthRegistrationSuccess  extends AuthBlocState {}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthRepository _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) { emit(AuthAuthenticated(user)); }
      else { emit(AuthUnauthenticated()); }
    } catch (_) { emit(AuthUnauthenticated()); }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signIn(email: event.email, password: event.password);
      emit(AuthAuthenticated(user));
    } catch (e) { emit(AuthError(e.toString())); }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.signUp(email: event.email, password: event.password, fullName: event.fullName, role: event.role);
      emit(AuthRegistrationSuccess());
    } catch (e) { emit(AuthError(e.toString())); }
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signUp(email: event.email, password: event.password, fullName: event.fullName, role: 'patient');
      emit(AuthAuthenticated(user));
    } catch (e) { emit(AuthError(e.toString())); }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthBlocState> emit) async {
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) { emit(AuthError(e.toString())); }
  }

  Future<void> _onForgotPasswordRequested(AuthForgotPasswordRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      await _repo.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) { emit(AuthError(e.toString())); }
  }
}
