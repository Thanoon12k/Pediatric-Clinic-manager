// ignore_for_file: constant_identifier_names
enum UserRole { admin, doctor, patient }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['email'] ?? '',
      role: _parseRole(json['role'] as String? ?? 'patient'),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role.name,
    'phone': phone,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  static UserRole _parseRole(String r) {
    switch (r) {
      case 'admin': return UserRole.admin;
      case 'doctor': return UserRole.doctor;
      default: return UserRole.patient;
    }
  }

  UserModel copyWith({String? fullName, String? phone, String? avatarUrl}) => UserModel(
    id: id, email: email, role: role, createdAt: createdAt,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}
