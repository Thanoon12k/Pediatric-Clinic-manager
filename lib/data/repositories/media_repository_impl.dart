import 'dart:io';
import '../../data/datasources/media_datasource.dart';
import '../../data/models/media_file_model.dart';
import '../../domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaDataSource _ds;
  MediaRepositoryImpl(this._ds);

  @override
  Future<List<MediaFileModel>> getPatientMedia(String patientId) => _ds.getPatientMedia(patientId);

  @override
  Future<MediaFileModel> uploadMedia({
    required String patientId,
    required String uploadedBy,
    required File file,
    required String type,
    String? caption,
  }) => _ds.uploadMedia(patientId: patientId, uploadedBy: uploadedBy, file: file, type: type, caption: caption);

  @override Future<void> deleteMedia(String id) async {
    // Fetch the URL first so we can remove from storage too
    final mediaList = await _ds.getPatientMedia('');  // fallback — datasource handles delete by id+url
    final media = mediaList.where((m) => m.id == id).toList();
    final url = media.isNotEmpty ? media.first.url : '';
    await _ds.deleteMedia(id, url);
  }
}
