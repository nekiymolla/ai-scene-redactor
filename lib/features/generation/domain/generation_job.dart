import '../../../core/errors/app_failure.dart';

enum GenerationStatus {
  /// Media is being uploaded to the backend.
  uploading,

  /// Accepted by the backend, waiting for a provider slot.
  queued,

  /// The provider is generating.
  processing,
  succeeded,
  failed,
  cancelled;

  bool get isTerminal =>
      this == succeeded || this == failed || this == cancelled;
}

/// Client-side view of a generation task tracked by the backend.
class GenerationJob {
  const GenerationJob({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.isSynthetic,
    this.progress,
    this.statusMessage,
    this.estimatedRemaining,
    this.failure,
  });

  final String id;
  final GenerationStatus status;
  final DateTime createdAt;

  /// 0..1 within the current [status] when reported, otherwise null
  /// (indeterminate).
  final double? progress;

  /// Optional human-readable stage, e.g. "Возвращаем оригинальный звук".
  final String? statusMessage;

  /// Only when the backend or provider can estimate it.
  final Duration? estimatedRemaining;

  /// Set when [status] is [GenerationStatus.failed].
  final GenerationFailure? failure;

  /// True when produced by the mock pipeline. The UI must label such results
  /// so a placeholder is never presented as real AI output.
  final bool isSynthetic;
}

/// The finished output of a succeeded job.
class GenerationResult {
  const GenerationResult({
    required this.jobId,
    required this.videoUri,
    required this.isSynthetic,
  });

  final String jobId;

  /// Remote URL from the backend or a local file URI.
  final Uri videoUri;
  final bool isSynthetic;
}
