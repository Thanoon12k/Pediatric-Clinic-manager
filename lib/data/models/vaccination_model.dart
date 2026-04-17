enum VaccinationStatus { given, due, overdue }

class VaccinationModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String vaccineName;
  final DateTime? dateGiven;
  final DateTime? nextDueDate;
  final VaccinationStatus status;
  final int doseNumber;
  final String? batchNumber;
  final String? sideEffects;
  final String? notes;
  final DateTime createdAt;

  const VaccinationModel({
    required this.id, required this.patientId, required this.doctorId,
    required this.vaccineName, this.dateGiven, this.nextDueDate,
    this.status = VaccinationStatus.due, this.doseNumber = 1,
    this.batchNumber, this.sideEffects, this.notes,
    required this.createdAt,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    VaccinationStatus status;
    switch (json['status'] as String? ?? 'due') {
      case 'given': status = VaccinationStatus.given; break;
      case 'overdue': status = VaccinationStatus.overdue; break;
      default: status = VaccinationStatus.due;
    }
    return VaccinationModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      vaccineName: json['vaccine_name'] as String,
      dateGiven: json['date_given'] != null ? DateTime.parse(json['date_given'] as String) : null,
      nextDueDate: json['next_due_date'] != null ? DateTime.parse(json['next_due_date'] as String) : null,
      status: status,
      doseNumber: json['dose_number'] as int? ?? 1,
      batchNumber: json['batch_number'] as String?,
      sideEffects: json['side_effects'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'patient_id': patientId, 'doctor_id': doctorId,
    'vaccine_name': vaccineName,
    'date_given': dateGiven?.toIso8601String().split('T').first,
    'next_due_date': nextDueDate?.toIso8601String().split('T').first,
    'status': status.name, 'dose_number': doseNumber,
    'batch_number': batchNumber, 'side_effects': sideEffects, 'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
