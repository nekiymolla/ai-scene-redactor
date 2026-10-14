import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/app_storage.dart';
import '../domain/generation_gateway.dart';
import '../domain/generation_job.dart';
import '../domain/generation_request.dart';

enum MockScenario { success, failure }

/// Durations of the simulated pipeline stages.
class MockTimeline {
  const MockTimeline({
    required this.upload,
    required this.queue,
    required this.processing,
  });

  static const demo = MockTimeline(
    upload: Duration(seconds: 3),
    queue: Duration(seconds: 3),
    processing: Duration(seconds: 14),
  );

  final Duration upload;
  final Duration queue;
  final Duration processing;

  Duration get total => upload + queue + processing;

  /// Where in processing the failure scenario fails.
  static const failAt = 0.6;
}

/// Simulates a generation backend without network or AI.
///
/// Status is derived from wall-clock time since submission, and jobs are
/// kept in a small JSON file, so a "running" job survives an app restart
/// just like a real server-side job would. The "result" is the user's own
/// source video, always flagged [GenerationJob.isSynthetic].
class MockGenerationGateway implements GenerationGateway {
  MockGenerationGateway(
    this._storage,
    this._scenario, {
    this.timeline = MockTimeline.demo,
    MockJobStore? store,
  }) : _store = store ?? FileMockJobStore(_storage);

  final AppStorage _storage;
  final MockScenario Function() _scenario;
  final MockTimeline timeline;
  final MockJobStore _store;

  Map<String, MockJob>? _jobs;

  @override
  Future<GenerationJob> submit(GenerationRequest request) async {
    final jobs = await _load();
    final job = MockJob(
      id: 'mock-${const Uuid().v4()}',
      createdAt: clock.now(),
      scenario: _scenario(),
      sourceRelativePath: request.sourceVideo.relativePath,
      keepAudio: request.settings.keepOriginalAudio,
    );
    jobs[job.id] = job;
    await _save();
    return _status(job);
  }

  @override
  Future<GenerationJob> getStatus(String jobId) async =>
      _status(await _find(jobId));

  @override
  Future<void> cancel(String jobId) async {
    final job = await _find(jobId);
    if (_status(job).status.isTerminal) return;
    job.cancelledAt = clock.now();
    await _save();
  }

  @override
  Future<GenerationResult> getResult(String jobId) async {
    final job = await _find(jobId);
    if (_status(job).status != GenerationStatus.succeeded) {
      throw const GenerationFailure(
        'Результат ещё не готов.',
        code: 'result_not_ready',
      );
    }
    return GenerationResult(
      jobId: jobId,
      videoUri: Uri.file(_storage.file(job.sourceRelativePath).path),
      isSynthetic: true,
    );
  }

  GenerationJob _status(MockJob job) {
    final t = timeline;
    final elapsed = (job.cancelledAt ?? clock.now()).difference(job.createdAt);
    final remaining = t.total - elapsed;

    GenerationJob make(
      GenerationStatus status, {
      double? progress,
      String? message,
      GenerationFailure? failure,
    }) {
      return GenerationJob(
        id: job.id,
        status: status,
        createdAt: job.createdAt,
        isSynthetic: true,
        progress: progress?.clamp(0.0, 1.0),
        statusMessage: message,
        estimatedRemaining: status.isTerminal || remaining.isNegative
            ? null
            : remaining,
        failure: failure,
      );
    }

    if (job.cancelledAt != null) return make(GenerationStatus.cancelled);

    if (elapsed < t.upload) {
      return make(
        GenerationStatus.uploading,
        progress: elapsed.inMilliseconds / t.upload.inMilliseconds,
        message: 'Загружаем видео и фото',
      );
    }
    if (elapsed < t.upload + t.queue) {
      return make(GenerationStatus.queued, message: 'Ждём свободную модель');
    }

    final p =
        (elapsed - t.upload - t.queue).inMilliseconds /
        t.processing.inMilliseconds;
    if (job.scenario == MockScenario.failure && p >= MockTimeline.failAt) {
      return make(
        GenerationStatus.failed,
        failure: const GenerationFailure(
          'Модель не смогла обработать видео. Это имитация ошибки '
          'в демо-режиме.',
          code: 'mock_failure',
          retryable: true,
        ),
      );
    }
    if (p < 1) {
      final message = p < 0.3
          ? 'Анализируем кадры и персонажей'
          : p < 0.8
          ? 'Генерируем сцену'
          : job.keepAudio
          ? 'Возвращаем оригинальный звук'
          : 'Собираем видео';
      return make(GenerationStatus.processing, progress: p, message: message);
    }
    return make(GenerationStatus.succeeded);
  }

  Future<MockJob> _find(String id) async {
    final job = (await _load())[id];
    if (job == null) {
      throw const GenerationFailure(
        'Задача не найдена. Запустите генерацию заново.',
        code: 'job_not_found',
        retryable: true,
      );
    }
    return job;
  }

  Future<Map<String, MockJob>> _load() async => _jobs ??= await _store.load();

  Future<void> _save() => _store.save(_jobs!);
}

/// Where mock jobs live between app launches.
abstract interface class MockJobStore {
  Future<Map<String, MockJob>> load();

  Future<void> save(Map<String, MockJob> jobs);
}

class FileMockJobStore implements MockJobStore {
  FileMockJobStore(this._storage);

  final AppStorage _storage;

  File get _file => _storage.file('mock/jobs.json');

  @override
  Future<Map<String, MockJob>> load() async {
    try {
      if (!await _file.exists()) return {};
      final raw = jsonDecode(await _file.readAsString()) as Map;
      return {
        for (final e in raw.entries)
          e.key as String: MockJob.fromJson((e.value as Map).cast()),
      };
    } catch (_) {
      // A broken mock store only loses demo jobs.
      return {};
    }
  }

  @override
  Future<void> save(Map<String, MockJob> jobs) async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(
        jsonEncode({for (final e in jobs.entries) e.key: e.value.toJson()}),
      );
    } on FileSystemException catch (e) {
      throw StorageFailure('Не удалось сохранить задачу.', cause: e);
    }
  }
}

/// Keeps jobs only for the lifetime of the object. Used in tests.
class MemoryMockJobStore implements MockJobStore {
  Map<String, MockJob> _jobs = {};

  @override
  Future<Map<String, MockJob>> load() async => _jobs;

  @override
  Future<void> save(Map<String, MockJob> jobs) async => _jobs = jobs;
}

class MockJob {
  MockJob({
    required this.id,
    required this.createdAt,
    required this.scenario,
    required this.sourceRelativePath,
    required this.keepAudio,
    this.cancelledAt,
  });

  factory MockJob.fromJson(Map<String, Object?> json) {
    final cancelled = json['cancelledAt'] as int?;
    return MockJob(
      id: json['id']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']! as int),
      scenario: MockScenario.values.byName(json['scenario']! as String),
      sourceRelativePath: json['source']! as String,
      keepAudio: json['keepAudio'] as bool? ?? true,
      cancelledAt: cancelled == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(cancelled),
    );
  }

  final String id;
  final DateTime createdAt;
  final MockScenario scenario;
  final String sourceRelativePath;
  final bool keepAudio;
  DateTime? cancelledAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'scenario': scenario.name,
    'source': sourceRelativePath,
    'keepAudio': keepAudio,
    'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
  };
}
