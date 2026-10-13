import '../../generation/domain/generation_job.dart';
import '../../generation/domain/media_asset.dart';

/// A user's video transformation project, stored on the device.
///
/// Has no owner field on purpose: the MVP is account-free. When accounts
/// arrive, ownership lives on the backend and local projects get migrated.
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceVideo,
    this.prompt = '',
    this.lastJobId,
    this.lastJobStatus,
    this.resultLocalPath,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MediaAsset sourceVideo;
  final String prompt;
  final String? lastJobId;
  final GenerationStatus? lastJobStatus;

  /// Downloaded result, if any.
  final String? resultLocalPath;
}
