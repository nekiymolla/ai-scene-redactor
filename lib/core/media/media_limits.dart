import '../errors/app_failure.dart';

/// Client-side media limits. Chosen to fit the strictest planned provider
/// (Kling O3 Edit: 3–15 s, ≤200 MB; element photos ≥300×300 px), see
/// docs/AI_PIPELINE.md. The backend re-validates.
class VideoLimits {
  const VideoLimits({
    required this.minDuration,
    required this.maxDuration,
    required this.maxBytes,
  });

  /// The video to transform.
  static const source = VideoLimits(
    minDuration: Duration(seconds: 3),
    maxDuration: Duration(seconds: 15),
    maxBytes: 200 * 1024 * 1024,
  );

  /// A style/environment reference; only a few frames of it matter.
  static const reference = VideoLimits(
    minDuration: Duration(seconds: 1),
    maxDuration: Duration(seconds: 60),
    maxBytes: 200 * 1024 * 1024,
  );

  final Duration minDuration;
  final Duration maxDuration;
  final int maxBytes;

  MediaFailure? check({required Duration duration, required int sizeBytes}) {
    if (sizeBytes > maxBytes) {
      return MediaFailure(
        'Файл слишком большой: максимум ${maxBytes ~/ (1024 * 1024)} МБ.',
      );
    }
    if (duration < minDuration) {
      return MediaFailure(
        'Видео слишком короткое: нужно не меньше ${minDuration.inSeconds} с.',
      );
    }
    if (duration > maxDuration + const Duration(milliseconds: 500)) {
      return MediaFailure(
        'Видео длиннее ${maxDuration.inSeconds} с. Обрежьте его в галерее '
        'и выберите снова.',
      );
    }
    return null;
  }
}

abstract final class ImageLimits {
  static const minSide = 300;

  /// Picked photos are re-encoded to JPEG no larger than this on the long side.
  static const maxSide = 2048;

  static MediaFailure? check({required int width, required int height}) {
    if (width < minSide || height < minSide) {
      return const MediaFailure(
        'Фото слишком маленькое: нужно минимум $minSide×$minSide пикселей.',
      );
    }
    return null;
  }
}
