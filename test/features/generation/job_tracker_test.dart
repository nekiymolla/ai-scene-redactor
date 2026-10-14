import 'package:ai_scene_changer/core/errors/app_failure.dart';
import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/features/generation/application/job_tracker.dart';
import 'package:ai_scene_changer/features/generation/data/mock_generation_gateway.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_gateway.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_request.dart';
import 'package:ai_scene_changer/features/projects/domain/project.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

Project _project({String? jobId, GenerationStatus? status}) => Project(
  id: 'p1',
  title: 'Тест',
  createdAt: DateTime(2026, 10, 14),
  updatedAt: DateTime(2026, 10, 14),
  sourceVideo: const MediaAsset(
    id: 'v',
    kind: MediaKind.video,
    relativePath: 'projects/p1/media/v.mp4',
  ),
  prompt: 'Осенний лес',
  lastJobId: jobId,
  lastJobStatus: status,
);

/// Delegates to the mock but can be told to fail like a flaky network.
class _FlakyGateway implements GenerationGateway {
  _FlakyGateway(this.inner);

  final GenerationGateway inner;
  var offline = false;
  var statusCalls = 0;

  @override
  Future<GenerationJob> submit(GenerationRequest r) => inner.submit(r);

  @override
  Future<GenerationJob> getStatus(String id) {
    statusCalls++;
    if (offline) return Future.error(const NetworkFailure());
    return inner.getStatus(id);
  }

  @override
  Future<void> cancel(String id) => inner.cancel(id);

  @override
  Future<GenerationResult> getResult(String id) => inner.getResult(id);
}

void main() {
  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  ProviderContainer containerWith(List<Override> overrides) {
    final c = ProviderContainer(overrides: [...env.overrides, ...overrides]);
    addTearDown(c.dispose);
    return c;
  }

  test('start → polls to success and stores the synthetic result', () {
    fakeAsync((async) {
      env.repository.save(_project());
      final c = containerWith(const []);
      final provider = jobTrackerProvider('p1');
      c.listen(provider, (_, _) {});
      async.flushMicrotasks();
      expect(c.read(provider).loading, isFalse);

      c.read(provider.notifier).start();
      async.flushMicrotasks();
      expect(c.read(provider).status, GenerationStatus.uploading);

      async.elapse(const Duration(seconds: 3));
      expect(c.read(provider).status, GenerationStatus.processing);

      async.elapse(const Duration(seconds: 4));
      final state = c.read(provider);
      expect(state.status, GenerationStatus.succeeded);
      expect(state.project!.hasResult, isTrue);
      expect(state.project!.resultIsSynthetic, isTrue);
      expect(state.project!.resultRelativePath, 'projects/p1/media/v.mp4');

      env.repository.byId('p1').then((p) {
        expect(p!.lastJobStatus, GenerationStatus.succeeded);
      });
      async.flushMicrotasks();
    });
  });

  test('resumes a job that was running before the app restarted', () {
    fakeAsync((async) {
      late String jobId;
      env.gateway.submit(_project().toRequest()).then((job) => jobId = job.id);
      async.flushMicrotasks();
      env.repository.save(
        _project(jobId: jobId, status: GenerationStatus.uploading),
      );
      // Time passes while the app is closed.
      async.elapse(const Duration(seconds: 3));

      final c = containerWith(const []);
      c.listen(jobTrackerProvider('p1'), (_, _) {});
      async.elapse(const Duration(milliseconds: 100));
      expect(
        c.read(jobTrackerProvider('p1')).status,
        GenerationStatus.processing,
      );

      async.elapse(const Duration(seconds: 4));
      expect(
        c.read(jobTrackerProvider('p1')).status,
        GenerationStatus.succeeded,
      );
    });
  });

  test('keeps retrying with backoff while offline, then recovers', () {
    fakeAsync((async) {
      final flaky = _FlakyGateway(env.gateway);
      env.repository.save(_project());
      env.customGateway = flaky;
      final c = containerWith(const []);
      final provider = jobTrackerProvider('p1');
      c.listen(provider, (_, _) {});
      async.flushMicrotasks();
      c.read(provider.notifier).start();
      async.flushMicrotasks();

      flaky.offline = true;
      async.elapse(const Duration(seconds: 20));
      expect(c.read(provider).problem, isA<NetworkFailure>());
      // 250 ms, then 0.5, 1, 2, 4, 8, 10 s… — far fewer calls than plain polling.
      expect(flaky.statusCalls, lessThan(10));

      flaky.offline = false;
      async.elapse(const Duration(seconds: 11));
      expect(c.read(provider).problem, isNull);
      expect(c.read(provider).status, GenerationStatus.succeeded);
    });
  });

  test('cancel stops polling and records the cancellation', () {
    fakeAsync((async) {
      env.repository.save(_project());
      final c = containerWith(const []);
      final provider = jobTrackerProvider('p1');
      c.listen(provider, (_, _) {});
      async.flushMicrotasks();
      c.read(provider.notifier).start();
      async.elapse(const Duration(seconds: 1));

      c.read(provider.notifier).cancel();
      async.elapse(const Duration(seconds: 10));
      expect(c.read(provider).status, GenerationStatus.cancelled);
      expect(c.read(provider).project!.hasActiveJob, isFalse);
    });
  });

  test('a failed job can be started again', () {
    fakeAsync((async) {
      env.scenario = MockScenario.failure;
      env.repository.save(_project());
      final c = containerWith(const []);
      final provider = jobTrackerProvider('p1');
      c.listen(provider, (_, _) {});
      async.flushMicrotasks();
      c.read(provider.notifier).start();
      async.elapse(const Duration(seconds: 10));
      expect(c.read(provider).status, GenerationStatus.failed);
      expect(c.read(provider).project!.lastFailureMessage, isNotNull);

      env.scenario = MockScenario.success;
      c.read(provider.notifier).start();
      async.elapse(const Duration(seconds: 10));
      expect(c.read(provider).status, GenerationStatus.succeeded);
      expect(c.read(provider).project!.lastFailureMessage, isNull);
    });
  });

  test('start validates the project first', () {
    fakeAsync((async) {
      env.repository.save(
        Project(
          id: 'p1',
          title: 'Пустой',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          sourceVideo: _project().sourceVideo,
        ),
      );
      final c = containerWith(const []);
      final provider = jobTrackerProvider('p1');
      c.listen(provider, (_, _) {});
      async.flushMicrotasks();

      AppFailure? failure;
      c.read(provider.notifier).start().then((f) => failure = f);
      async.flushMicrotasks();
      expect(failure, isA<ValidationFailure>());
      expect(c.read(provider).project!.lastJobId, isNull);
    });
  });
}
