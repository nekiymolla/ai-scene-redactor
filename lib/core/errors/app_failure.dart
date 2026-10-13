/// Typed, user-presentable failures.
///
/// Data-layer code catches low-level exceptions (IO, HTTP, platform) and maps
/// them to one of these, so the UI can switch exhaustively instead of
/// rendering raw exception text.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Short message safe to show to the user.
  final String message;

  /// Original error, kept for logging. Never shown to the user.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity, timeout or unreachable backend.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'Нет соединения с сервером. Проверьте интернет и повторите попытку.',
  ]);
}

/// User input that cannot be accepted as is.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {required this.field});

  final String field;
}

/// A picked file is unreadable, unsupported, too large or too long.
final class MediaFailure extends AppFailure {
  const MediaFailure(super.message, {super.cause});
}

/// Permission to the gallery or storage was denied.
final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

/// The generation job failed on the backend or AI provider side.
final class GenerationFailure extends AppFailure {
  const GenerationFailure(super.message, {this.code, this.retryable = false});

  /// Stable machine-readable code from the backend, e.g. `provider_timeout`.
  final String? code;
  final bool retryable;
}

/// Local persistence failed.
final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

/// Anything not mapped above. Indicates a bug or an unhandled edge case.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.cause})
    : super('Что-то пошло не так. Попробуйте ещё раз.');
}
