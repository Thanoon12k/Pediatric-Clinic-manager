class MediaFileModel {
  final String id;
  final String patientId;
  final String uploadedBy;
  final String type;  // image, audio, pdf, document
  final String url;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? caption;
  final DateTime createdAt;

  const MediaFileModel({
    required this.id, required this.patientId, required this.uploadedBy,
    required this.type, required this.url,
    this.fileName, this.fileSizeBytes, this.mimeType, this.caption,
    required this.createdAt,
  });

  factory MediaFileModel.fromJson(Map<String, dynamic> json) => MediaFileModel(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    uploadedBy: json['uploaded_by'] as String,
    type: json['type'] as String,
    url: json['url'] as String,
    fileName: json['file_name'] as String?,
    fileSizeBytes: json['file_size_bytes'] as int?,
    mimeType: json['mime_type'] as String?,
    caption: json['caption'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'patient_id': patientId, 'uploaded_by': uploadedBy,
    'type': type, 'url': url, 'file_name': fileName,
    'file_size_bytes': fileSizeBytes, 'mime_type': mimeType,
    'caption': caption, 'created_at': createdAt.toIso8601String(),
  };

  String get sizeDisplay {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
