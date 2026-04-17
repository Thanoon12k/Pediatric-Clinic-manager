import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yadati/data/models/patient_model.dart';
import 'package:yadati/domain/repositories/patient_repository.dart';
import 'package:yadati/presentation/blocs/patient/patient_bloc.dart';

class MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late MockPatientRepository mockRepo;
  late PatientBloc bloc;

  final testPatient = PatientModel(
    id: 'p1', doctorId: 'd1', fullName: 'أحمد محمد',
    dateOfBirth: DateTime(2018, 3, 15), gender: Gender.male,
    guardianName: 'محمد', guardianPhone: '07701234567',
    treatmentStatus: TreatmentStatus.underTreatment,
    allowChat: true, allowPhotos: true, allowVoice: true, allowMessages: true,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockPatientRepository();
    bloc = PatientBloc(mockRepo);
    registerFallbackValue(testPatient);
  });
  tearDown(() => bloc.close());

  group('PatientBloc', () {
    test('initial state is PatientInitial', () {
      expect(bloc.state, isA<PatientInitial>());
    });

    blocTest<PatientBloc, PatientState>(
      'emits [PatientLoading, PatientsLoaded] when LoadPatients succeeds',
      build: () {
        when(() => mockRepo.getPatients(doctorId: any(named: 'doctorId'), search: any(named: 'search')))
            .thenAnswer((_) async => [testPatient]);
        return bloc;
      },
      act: (b) => b.add(LoadPatients(doctorId: 'd1')),
      expect: () => [isA<PatientLoading>(), isA<PatientsLoaded>()],
    );

    blocTest<PatientBloc, PatientState>(
      'emits [PatientLoading, PatientError] when LoadPatients fails',
      build: () {
        when(() => mockRepo.getPatients(doctorId: any(named: 'doctorId'), search: any(named: 'search')))
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(LoadPatients(doctorId: 'd1')),
      expect: () => [isA<PatientLoading>(), isA<PatientError>()],
    );
  });
}
