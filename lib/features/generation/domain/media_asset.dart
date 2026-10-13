enum MediaKind { video, image }

/// A media file the user picked on the device.
///
/// [localPath] points to an app-owned copy (not the gallery original), so the
/// project keeps working even if the user deletes the source from the gallery.
class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.kind,
    required this.localPath,
    this.sizeBytes,
    this.duration,
    this.width,
    this.height,
  });

  final String id;
  final MediaKind kind;
  final String localPath;
  final int? sizeBytes;

  /// Only for [MediaKind.video].
  final Duration? duration;
  final int? width;
  final int? height;

  bool get isVideo => kind == MediaKind.video;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'localPath': localPath,
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
      localPath: json['localPath']! as String,
      sizeBytes: json['sizeBytes'] as int?,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}
