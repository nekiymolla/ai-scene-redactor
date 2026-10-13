import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the app talks to the generation backend.
enum GenerationMode {
  /// Local simulation. No network, no AI, results are clearly labelled as
  /// synthetic in the UI.
  mock,

  /// The project backend (see `backend/`), which owns all AI provider keys.
  backend,
}

/// Build-time configuration passed via `--dart-define`.
///
/// Holds only public, non-secret values. AI provider keys never reach the
/// client: they live in the backend environment.
class AppConfig {
  const AppConfig({required this.generationMode, required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const mode = String.fromEnvironment(
      'GENERATION_MODE',
      defaultValue: 'mock',
    );
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      generationMode: GenerationMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => GenerationMode.mock,
      ),
      apiBaseUrl: baseUrl.isEmpty ? null : Uri.parse(baseUrl),
    );
  }

  final GenerationMode generationMode;
  final Uri? apiBaseUrl;

  bool get isMock => generationMode == GenerationMode.mock;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
