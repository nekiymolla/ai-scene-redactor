import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/storage/app_storage.dart';
import '../../projects/application/projects_providers.dart';
import '../data/mock_generation_gateway.dart';
import '../domain/generation_gateway.dart';
import '../domain/generation_job.dart';
import '../domain/generation_request.dart';
import 'generation_service.dart';

/// Demo-only switch from Settings: makes the next mock job fail, to show
/// error handling without a real backend.
class MockScenarioController extends Notifier<MockScenario> {
  @override
  MockScenario build() => MockScenario.success;

  void set(MockScenario scenario) => state = scenario;
}

final mockScenarioProvider =
    NotifierProvider<MockScenarioController, MockScenario>(
      MockScenarioController.new,
    );

final generationGatewayProvider = Provider<GenerationGateway>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.generationMode) {
    GenerationMode.mock => MockGenerationGateway(
      ref.watch(appStorageProvider),
      () => ref.read(mockScenarioProvider),
    ),
    GenerationMode.backend => const _BackendNotConnectedGateway(),
  };
});

final generationServiceProvider = Provider<GenerationService>(
  (ref) => GenerationService(
    ref.watch(generationGatewayProvider),
    ref.watch(projectsRepositoryProvider),
    ref.watch(appStorageProvider),
  ),
);

/// How often a running job is polled. Overridden in tests.
final pollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// Stand-in until the backend exists (stage 4): fails clearly instead of
/// pretending to work.
class _BackendNotConnectedGateway implements GenerationGateway {
  const _BackendNotConnectedGateway();

  static const _failure = GenerationFailure(
    'Сервер обработки ещё не подключён. Соберите приложение в демо-режиме.',
    code: 'backend_not_connected',
  );

  @override
  Future<GenerationJob> submit(GenerationRequest request) =>
      Future.error(_failure);

  @override
  Future<GenerationJob> getStatus(String jobId) => Future.error(_failure);

  @override
  Future<void> cancel(String jobId) => Future.error(_failure);

  @override
  Future<GenerationResult> getResult(String jobId) => Future.error(_failure);
}
