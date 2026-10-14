import '../../generation/domain/generation_job.dart';
import '../../generation/domain/generation_request.dart';
import '../../../core/media/media_asset.dart';

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
    this.characters = const [],
    this.styleReferences = const [],
    this.prompt = '',
    this.settings = const GenerationSettings(),
    this.lastJobId,
    this.lastJobStatus,
    this.lastFailureMessage,
    this.resultRelativePath,
    this.resultIsSynthetic = false,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MediaAsset sourceVideo;
  final List<CharacterReference> characters;
  final List<MediaAsset> styleReferences;
  final String prompt;
  final GenerationSettings settings;
  final String? lastJobId;
  final GenerationStatus? lastJobStatus;

  /// User-facing reason of the last failed job.
  final String? lastFailureMessage;

  /// Result video, relative to the app storage root.
  final String? resultRelativePath;

  /// The result came from the mock pipeline and must be labelled as such.
  final bool resultIsSynthetic;

  bool get hasActiveJob =>
      lastJobId != null && !(lastJobStatus?.isTerminal ?? false);

  bool get hasResult =>
      lastJobStatus == GenerationStatus.succeeded && resultRelativePath != null;

  static const _keep = Object();

  /// Nullable fields accept an explicit `null` to clear them.
  Project copyWith({
    String? title,
    DateTime? updatedAt,
    Object? lastJobId = _keep,
    Object? lastJobStatus = _keep,
    Object? lastFailureMessage = _keep,
    Object? resultRelativePath = _keep,
    bool? resultIsSynthetic,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceVideo: sourceVideo,
      characters: characters,
      styleReferences: styleReferences,
      prompt: prompt,
      settings: settings,
      lastJobId: identical(lastJobId, _keep)
          ? this.lastJobId
          : lastJobId as String?,
      lastJobStatus: identical(lastJobStatus, _keep)
          ? this.lastJobStatus
          : lastJobStatus as GenerationStatus?,
      lastFailureMessage: identical(lastFailureMessage, _keep)
          ? this.lastFailureMessage
          : lastFailureMessage as String?,
      resultRelativePath: identical(resultRelativePath, _keep)
          ? this.resultRelativePath
          : resultRelativePath as String?,
      resultIsSynthetic: resultIsSynthetic ?? this.resultIsSynthetic,
    );
  }

  GenerationRequest toRequest() => GenerationRequest(
    sourceVideo: sourceVideo,
    prompt: prompt,
    characters: characters,
    styleReferences: styleReferences,
    settings: settings,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'sourceVideo': sourceVideo.toJson(),
    'characters': [for (final c in characters) c.toJson()],
    'styleReferences': [for (final s in styleReferences) s.toJson()],
    'prompt': prompt,
    'settings': settings.toJson(),
    'lastJobId': lastJobId,
    'lastJobStatus': lastJobStatus?.name,
    'lastFailureMessage': lastFailureMessage,
    'resultRelativePath': resultRelativePath,
    'resultIsSynthetic': resultIsSynthetic,
  };

  factory Project.fromJson(Map<String, Object?> json) {
    final status = json['lastJobStatus'] as String?;
    return Project(
      id: json['id']! as String,
      title: json['title']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toLocal(),
      sourceVideo: MediaAsset.fromJson((json['sourceVideo']! as Map).cast()),
      characters: [
        for (final c in json['characters'] as List? ?? const [])
          CharacterReference.fromJson((c as Map).cast()),
      ],
      styleReferences: [
        for (final s in json['styleReferences'] as List? ?? const [])
          MediaAsset.fromJson((s as Map).cast()),
      ],
      prompt: json['prompt'] as String? ?? '',
      settings: json['settings'] == null
          ? const GenerationSettings()
          : GenerationSettings.fromJson((json['settings']! as Map).cast()),
      lastJobId: json['lastJobId'] as String?,
      lastJobStatus: status == null
          ? null
          : GenerationStatus.values.byName(status),
      lastFailureMessage: json['lastFailureMessage'] as String?,
      resultRelativePath: json['resultRelativePath'] as String?,
      resultIsSynthetic: json['resultIsSynthetic'] as bool? ?? false,
    );
  }
}
