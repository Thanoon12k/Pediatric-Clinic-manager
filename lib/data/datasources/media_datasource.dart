import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/media_file_model.dart';
import '../../core/constants/app_constants.dart';

abstract class MediaDataSource {
  Future<List<MediaFileModel>> getPatientMedia(String patientId);
  Future<MediaFileModel> uploadMedia({
    required String patientId, required String uploadedBy,
    required File file, required String type, String? caption,
  });
  Future<void> deleteMedia(String id, String url);
}

class MediaDataSourceImpl implements MediaDataSource {
  final SupabaseClient _client;
  const MediaDataSourceImpl(this._client);

  @override
  Future<List<MediaFileModel>> getPatientMedia(String patientId) async {
    final data = await _client
        .from(AppConstants.tableMediaFiles)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return data.map((e) => MediaFileModel.fromJson(e)).toList();
  }

  @override
  Future<MediaFileModel> uploadMedia({
    required String patientId, required String uploadedBy,
    required File file, required String type, String? caption,
  }) async {
    final ext = p.extension(file.path).replaceAll('.', '');
    final fileName = '${const Uuid().v4()}.$ext';
    final storagePath = '$patientId/$type/$fileName';
    final bytes = await file.readAsBytes();

    await _client.storage
        .from(AppConstants.bucketPatientMedia)
        .uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: _mimeType(ext)));

    final url = _client.storage
        .from(AppConstants.bucketPatientMedia)
        .getPublicUrl(storagePath);

    final fileStat = await file.stat();
    final data = await _client.from(AppConstants.tableMediaFiles).insert({
      'patient_id': patientId,
      'uploaded_by': uploadedBy,
      'type': type,
      'url': url,
      'file_name': p.basename(file.path),
      'file_size_bytes': fileStat.size,
      'mime_type': _mimeType(ext),
      'caption': caption,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return MediaFileModel.fromJson(data);
  }

  @override
  Future<void> deleteMedia(String id, String url) async {
    // Extract storage path from URL
    final uri = Uri.parse(url);
    final storagePath = uri.pathSegments
        .skipWhile((s) => s != AppConstants.bucketPatientMedia)
        .skip(1)
        .join('/');
    await _client.storage
        .from(AppConstants.bucketPatientMedia)
        .remove([storagePath]);
    await _client.from(AppConstants.tableMediaFiles).delete().eq('id', id);
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'mp3': return 'audio/mpeg';
      case 'm4a': return 'audio/m4a';
      case 'wav': return 'audio/wav';
      case 'pdf': return 'application/pdf';
      default: return 'application/octet-stream';
    }
  }
}
