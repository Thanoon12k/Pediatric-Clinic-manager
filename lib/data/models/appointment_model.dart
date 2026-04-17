enum AppointmentStatus { pending, confirmed, cancelled, completed }

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = AppointmentStatus.pending,
    this.reason,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    AppointmentStatus status;
    switch (json['status'] as String? ?? 'pending') {
      case 'confirmed': status = AppointmentStatus.confirmed; break;
      case 'cancelled': status = AppointmentStatus.cancelled; break;
      case 'completed': status = AppointmentStatus.completed; break;
      default: status = AppointmentStatus.pending;
    }
    return AppointmentModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      appointmentTime: json['appointment_time'] as String,
      status: status,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'patient_name': patientName,
    'appointment_date': '${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2,'0')}-${appointmentDate.day.toString().padLeft(2,'0')}',
    'appointment_time': appointmentTime,
    'status': status.name,
    'reason': reason,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
