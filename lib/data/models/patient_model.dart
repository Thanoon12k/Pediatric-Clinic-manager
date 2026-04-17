enum Gender { male, female }
enum TreatmentStatus { underTreatment, recovered }

class PatientModel {
  final String id;
  final String doctorId;
  final String? userId;
  final String fullName;
  final DateTime dateOfBirth;
  final Gender gender;
  final String? bloodType;
  final double? weight;
  final double? height;
  final String guardianName;
  final String guardianPhone;
  final String? guardianEmail;
  final String? address;
  final String? notes;
  final String? allergies;
  final String? chronicDiseases;
  final TreatmentStatus treatmentStatus;
  final DateTime? nextVisitDate;
  final String? avatarUrl;
  final bool allowChat;
  final bool allowPhotos;
  final bool allowVoice;
  final bool allowMessages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PatientModel({
    required this.id,
    required this.doctorId,
    this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.bloodType,
    this.weight,
    this.height,
    required this.guardianName,
    required this.guardianPhone,
    this.guardianEmail,
    this.address,
    this.notes,
    this.allergies,
    this.chronicDiseases,
    this.treatmentStatus = TreatmentStatus.underTreatment,
    this.nextVisitDate,
    this.avatarUrl,
    this.allowChat = true,
    this.allowPhotos = true,
    this.allowVoice = true,
    this.allowMessages = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Age display string (e.g., "3 سنوات" or "8 أشهر")
  String get ageDisplay {
    final now = DateTime.now();
    final months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (months < 1) return 'أقل من شهر';
    if (months < 12) return '$months ${_monthLabel(months)}';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years ${_yearLabel(years)}';
    return '$years ${_yearLabel(years)} و$rem ${_monthLabel(rem)}';
  }

  String _yearLabel(int n) => n == 1 ? 'سنة' : n == 2 ? 'سنتان' : n <= 10 ? 'سنوات' : 'سنة';
  String _monthLabel(int n) => n == 1 ? 'شهر' : n == 2 ? 'شهران' : n <= 10 ? 'أشهر' : 'شهر';

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] == 'female' ? Gender.female : Gender.male,
      bloodType: json['blood_type'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      guardianName: json['guardian_name'] as String? ?? '',
      guardianPhone: json['guardian_phone'] as String? ?? '',
      guardianEmail: json['guardian_email'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      allergies: json['allergies'] as String?,
      chronicDiseases: json['chronic_diseases'] as String?,
      treatmentStatus: json['treatment_status'] == 'recovered'
          ? TreatmentStatus.recovered
          : TreatmentStatus.underTreatment,
      nextVisitDate: json['next_visit_date'] != null ? DateTime.parse(json['next_visit_date'] as String) : null,
      avatarUrl: json['avatar_url'] as String?,
      allowChat: json['allow_chat'] as bool? ?? true,
      allowPhotos: json['allow_photos'] as bool? ?? true,
      allowVoice: json['allow_voice'] as bool? ?? true,
      allowMessages: json['allow_messages'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctor_id': doctorId,
    if (userId != null) 'user_id': userId,
    'full_name': fullName,
    'date_of_birth': '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2,'0')}-${dateOfBirth.day.toString().padLeft(2,'0')}',
    'gender': gender == Gender.female ? 'female' : 'male',
    'blood_type': bloodType,
    'weight': weight,
    'height': height,
    'guardian_name': guardianName,
    'guardian_phone': guardianPhone,
    'guardian_email': guardianEmail,
    'address': address,
    'notes': notes,
    'allergies': allergies,
    'chronic_diseases': chronicDiseases,
    'treatment_status': treatmentStatus == TreatmentStatus.recovered ? 'recovered' : 'under_treatment',
    'next_visit_date': nextVisitDate != null
        ? '${nextVisitDate!.year}-${nextVisitDate!.month.toString().padLeft(2,'0')}-${nextVisitDate!.day.toString().padLeft(2,'0')}'
        : null,
    'avatar_url': avatarUrl,
    'allow_chat': allowChat,
    'allow_photos': allowPhotos,
    'allow_voice': allowVoice,
    'allow_messages': allowMessages,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  PatientModel copyWith({
    TreatmentStatus? treatmentStatus, double? weight, double? height,
    DateTime? nextVisitDate, String? notes,
  }) => PatientModel(
    id: id, doctorId: doctorId, userId: userId, fullName: fullName,
    dateOfBirth: dateOfBirth, gender: gender, bloodType: bloodType,
    guardianName: guardianName, guardianPhone: guardianPhone,
    guardianEmail: guardianEmail, address: address, allergies: allergies,
    chronicDiseases: chronicDiseases, avatarUrl: avatarUrl,
    allowChat: allowChat, allowPhotos: allowPhotos,
    allowVoice: allowVoice, allowMessages: allowMessages, createdAt: createdAt,
    treatmentStatus: treatmentStatus ?? this.treatmentStatus,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    nextVisitDate: nextVisitDate ?? this.nextVisitDate,
    notes: notes ?? this.notes,
  );
}
