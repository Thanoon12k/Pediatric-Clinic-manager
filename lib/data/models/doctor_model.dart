class DoctorModel {
  final String id;
  final String userId;
  final String fullName;
  final String? specialty;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? licenseNumber;
  final String? bio;
  final List<int> availableDays;  // 1=Mon … 7=Sun
  final String workStartTime;     // "08:00"
  final String workEndTime;        // "17:00"
  final int appointmentDurationMinutes;
  final bool isActive;
  final DateTime createdAt;

  const DoctorModel({
    required this.id, required this.userId, required this.fullName,
    this.specialty, this.phone, this.email, this.avatarUrl,
    this.licenseNumber, this.bio,
    this.availableDays = const [1, 2, 3, 4, 6],
    this.workStartTime = '08:00',
    this.workEndTime = '17:00',
    this.appointmentDurationMinutes = 20,
    this.isActive = true,
    required this.createdAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    fullName: json['full_name'] as String,
    specialty: json['specialty'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    licenseNumber: json['license_number'] as String?,
    bio: json['bio'] as String?,
    availableDays: json['available_days'] != null
        ? List<int>.from(json['available_days'] as List)
        : [1, 2, 3, 4, 6],
    workStartTime: json['work_start_time'] as String? ?? '08:00',
    workEndTime: json['work_end_time'] as String? ?? '17:00',
    appointmentDurationMinutes: json['appointment_duration_minutes'] as int? ?? 20,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'full_name': fullName,
    'specialty': specialty, 'phone': phone, 'email': email,
    'avatar_url': avatarUrl, 'license_number': licenseNumber, 'bio': bio,
    'available_days': availableDays,
    'work_start_time': workStartTime, 'work_end_time': workEndTime,
    'appointment_duration_minutes': appointmentDurationMinutes,
    'is_active': isActive, 'created_at': createdAt.toIso8601String(),
  };
}
