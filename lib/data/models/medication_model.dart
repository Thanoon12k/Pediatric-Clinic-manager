class MedicationModel {
  final String id;
  final String doctorId;
  final String name;
  final String? genericName;
  final String? form;       // tablet, syrup, injection, drops
  final String? strength;
  final String? notes;
  final DateTime createdAt;

  const MedicationModel({
    required this.id, required this.doctorId, required this.name,
    this.genericName, this.form, this.strength, this.notes,
    required this.createdAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
    id: json['id'] as String,
    doctorId: json['doctor_id'] as String,
    name: json['name'] as String,
    genericName: json['generic_name'] as String?,
    form: json['form'] as String?,
    strength: json['strength'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'doctor_id': doctorId, 'name': name,
    'generic_name': genericName, 'form': form,
    'strength': strength, 'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;
  final DateTime prescribedAt;

  const PrescriptionModel({
    required this.id, required this.patientId, required this.doctorId,
    required this.medicationId, required this.medicationName,
    required this.dosage, required this.frequency, required this.durationDays,
    this.instructions, required this.prescribedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) => PrescriptionModel(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    doctorId: json['doctor_id'] as String,
    medicationId: json['medication_id'] as String,
    medicationName: json['medication_name'] as String? ?? '',
    dosage: json['dosage'] as String,
    frequency: json['frequency'] as String,
    durationDays: json['duration_days'] as int? ?? 7,
    instructions: json['instructions'] as String?,
    prescribedAt: DateTime.parse(json['prescribed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'patient_id': patientId, 'doctor_id': doctorId,
    'medication_id': medicationId, 'medication_name': medicationName,
    'dosage': dosage, 'frequency': frequency,
    'duration_days': durationDays, 'instructions': instructions,
    'prescribed_at': prescribedAt.toIso8601String(),
  };
}
