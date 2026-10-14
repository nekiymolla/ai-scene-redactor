import 'dart:io';

import 'package:ai_scene_changer/core/errors/app_failure.dart';
import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/core/storage/app_storage.dart';
import 'package:ai_scene_changer/features/generation/data/mock_generation_gateway.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_request.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

const _request = GenerationRequest(
  sourceVideo: MediaAsset(
    id: 'v',
    kind: MediaKind.video,
    relativePath: 'projects/p/media/v.mp4',
  ),
  prompt: 'Лес',
);

void main() {
  late Directory root;
  late AppStorage storage;
  var now = DateTime(2026, 10, 14, 12);
  var scenario = MockScenario.success;

  MockGenerationGateway gateway({MockJobStore? store}) => MockGenerationGateway(
    storage,
    () => scenario,
    store: store ?? MemoryMockJobStore(),
  );

  /// Runs [body] with a clock the test moves via [now].
  Future<void> timed(Future<void> Function() body) =>
      withClock(Clock(() => now), body);

  setUp(() {
    root = Directory.systemTemp.createTempSync('mock_gateway_');
    storage = AppStorage(root);
    now = DateTime(2026, 10, 14, 12);
    scenario = MockScenario.success;
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('walks through upload, queue, processing and success', () async {
    await timed(() async {
      final g = gateway();
      final job = await g.submit(_request);
      expect(job.status, GenerationStatus.uploading);
      expect(job.isSynthetic, isTrue);
      expect(job.estimatedRemaining, MockTimeline.demo.total);

      now = now.add(const Duration(seconds: 4));
      expect((await g.getStatus(job.id)).status, GenerationStatus.queued);

      now = now.add(const Duration(seconds: 9)); // 13 s: 7 s into processing
      final processing = await g.getStatus(job.id);
      expect(processing.status, GenerationStatus.processing);
      expect(processing.progress, closeTo(0.5, 0.01));
      expect(processing.statusMessage, 'Генерируем сцену');

      now = now.add(const Duration(seconds: 8));
      final done = await g.getStatus(job.id);
      expect(done.status, GenerationStatus.succeeded);
      expect(done.estimatedRemaining, isNull);

      final result = await g.getResult(job.id);
      expect(result.isSynthetic, isTrue);
      expect(storage.relativize(result.videoUri), 'projects/p/media/v.mp4');
    });
  });

  test(
    'the failure scenario fails mid-processing with a clear message',
    () async {
      await timed(() async {
        scenario = MockScenario.failure;
        final g = gateway();
        final job = await g.submit(_request);
        now = now.add(const Duration(seconds: 15));
        final failed = await g.getStatus(job.id);
        expect(failed.status, GenerationStatus.failed);
        expect(failed.failure?.retryable, isTrue);
        expect(failed.failure?.message, contains('демо-режиме'));
        expect(g.getResult(job.id), throwsA(isA<GenerationFailure>()));
      });
    },
  );

  test('cancel stops the job; cancelling a finished job is a no-op', () async {
    await timed(() async {
      final g = gateway();
      final job = await g.submit(_request);
      now = now.add(const Duration(seconds: 2));
      await g.cancel(job.id);
      now = now.add(const Duration(minutes: 1));
      expect((await g.getStatus(job.id)).status, GenerationStatus.cancelled);

      final other = await g.submit(_request);
      now = now.add(const Duration(minutes: 1));
      await g.cancel(other.id);
      expect((await g.getStatus(other.id)).status, GenerationStatus.succeeded);
    });
  });

  test('jobs survive a restart with the file store', () async {
    await timed(() async {
      final job = await gateway(
        store: FileMockJobStore(storage),
      ).submit(_request);
      now = now.add(const Duration(seconds: 10));
      final restored = gateway(store: FileMockJobStore(storage));
      expect(
        (await restored.getStatus(job.id)).status,
        GenerationStatus.processing,
      );
    });
  });

  test('unknown jobs fail with job_not_found', () async {
    await expectLater(
      gateway().getStatus('nope'),
      throwsA(
        isA<GenerationFailure>().having((f) => f.code, 'code', 'job_not_found'),
      ),
    );
  });
}
