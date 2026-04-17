import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yadati/data/models/user_model.dart';
import 'package:yadati/domain/repositories/auth_repository.dart';
import 'package:yadati/presentation/blocs/auth/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthBloc bloc;

  final testUser = UserModel(
    id: 'u1', email: 'doctor@test.com', fullName: 'Test Doctor',
    role: UserRole.doctor, createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    bloc = AuthBloc(mockRepo);
    registerFallbackValue(testUser);
  });
  tearDown(() => bloc.close());

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthBlocState>(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      build: () {
        when(() => mockRepo.signIn(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => testUser);
        return bloc;
      },
      act: (b) => b.add(AuthLoginRequested(email: 'doctor@test.com', password: '123456')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'emits [AuthLoading, AuthError] on failed login',
      build: () {
        when(() => mockRepo.signIn(email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(Exception('بيانات غير صحيحة'));
        return bloc;
      },
      act: (b) => b.add(AuthLoginRequested(email: 'x@x.com', password: 'wrong')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'emits [AuthLoading, AuthUnauthenticated] on logout',
      build: () {
        when(() => mockRepo.signOut()).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(AuthLogoutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );
  });
}
