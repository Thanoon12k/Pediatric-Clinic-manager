class ExaminationModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String type; // general, vision, hearing, growth, blood
  final DateTime examinationDate;
  final String? result;
  final String? notes;
  // Vision specific
  final String? leftEyeVision;
  final String? rightEyeVision;
  // Growth specific
  final double? weightAtExam;
  final double? heightAtExam;
  final DateTime createdAt;

  const ExaminationModel({
    required this.id, required this.patientId, required this.doctorId,
    required this.type, required this.examinationDate,
    this.result, this.notes,
    this.leftEyeVision, this.rightEyeVision,
    this.weightAtExam, this.heightAtExam,
    required this.createdAt,
  });

  factory ExaminationModel.fromJson(Map<String, dynamic> json) => ExaminationModel(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    doctorId: json['doctor_id'] as String,
    type: json['type'] as String? ?? 'general',
    examinationDate: DateTime.parse(json['examination_date'] as String),
    result: json['result'] as String?,
    notes: json['notes'] as String?,
    leftEyeVision: json['left_eye_vision'] as String?,
    rightEyeVision: json['right_eye_vision'] as String?,
    weightAtExam: (json['weight_at_exam'] as num?)?.toDouble(),
    heightAtExam: (json['height_at_exam'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'patient_id': patientId, 'doctor_id': doctorId,
    'type': type,
    'examination_date': examinationDate.toIso8601String().split('T').first,
    'result': result, 'notes': notes,
    'left_eye_vision': leftEyeVision, 'right_eye_vision': rightEyeVision,
    'weight_at_exam': weightAtExam, 'height_at_exam': heightAtExam,
    'created_at': createdAt.toIso8601String(),
  };
}

class GrowthRecordModel {
  final String id;
  final String patientId;
  final DateTime recordDate;
  final double? weight;
  final double? height;
  final double? headCircumference;
  final String? notes;
  final DateTime createdAt;

  const GrowthRecordModel({
    required this.id, required this.patientId, required this.recordDate,
    this.weight, this.height, this.headCircumference, this.notes,
    required this.createdAt,
  });

  factory GrowthRecordModel.fromJson(Map<String, dynamic> json) => GrowthRecordModel(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    recordDate: DateTime.parse(json['record_date'] as String),
    weight: (json['weight'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    headCircumference: (json['head_circumference'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'patient_id': patientId,
    'record_date': recordDate.toIso8601String().split('T').first,
    'weight': weight, 'height': height,
    'head_circumference': headCircumference, 'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
