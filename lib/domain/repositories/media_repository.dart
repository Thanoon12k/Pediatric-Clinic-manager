import 'dart:io';
import '../../data/models/media_file_model.dart';

abstract class MediaRepository {
  Future<List<MediaFileModel>> getPatientMedia(String patientId);
  Future<MediaFileModel> uploadMedia({
    required String patientId,
    required String uploadedBy,
    required File file,
    required String type,
    String? caption,
  });
  Future<void> deleteMedia(String id);
}
