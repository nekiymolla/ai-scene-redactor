enum MediaKind { video, image }

/// A media file the user picked, copied into app-owned storage.
///
/// Paths are relative to the app storage root (see `AppStorage`): on iOS the
/// absolute container path changes between app updates, so absolute paths
/// stored on disk would break.
class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.kind,
    required this.relativePath,
    this.thumbnailRelativePath,
    this.sizeBytes,
    this.duration,
    this.width,
    this.height,
  });

  final String id;
  final MediaKind kind;
  final String relativePath;

  /// JPEG preview frame, only for videos. May be missing if the platform
  /// could not extract a frame.
  final String? thumbnailRelativePath;
  final int? sizeBytes;

  /// Only for [MediaKind.video].
  final Duration? duration;
  final int? width;
  final int? height;

  bool get isVideo => kind == MediaKind.video;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'relativePath': relativePath,
    'thumbnailRelativePath': thumbnailRelativePath,
    'sizeBytes': sizeBytes,
    'durationMs': duration?.inMilliseconds,
    'width': width,
    'height': height,
  };

  factory MediaAsset.fromJson(Map<String, Object?> json) {
    final durationMs = json['durationMs'] as int?;
    return MediaAsset(
      id: json['id']! as String,
      kind: MediaKind.values.byName(json['kind']! as String),
      relativePath: json['relativePath']! as String,
      thumbnailRelativePath: json['thumbnailRelativePath'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}
