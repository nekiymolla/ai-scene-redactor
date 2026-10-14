import 'package:clock/clock.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/app_storage.dart';
import '../../projects/data/projects_repository.dart';
import '../../projects/domain/project.dart';
import '../domain/generation_gateway.dart';
import '../domain/generation_job.dart';

/// Starts, refreshes and cancels a project's generation job and keeps the
/// project's persisted job fields in sync, so the job can be resumed after
/// the app restarts. Throws [AppFailure].
class GenerationService {
  GenerationService(this._gateway, this._projects, this._storage);

  final GenerationGateway _gateway;
  final ProjectsRepository _projects;
  final AppStorage _storage;

  Future<(Project, GenerationJob)> start(Project project) async {
    final errors = project.toRequest().validate();
    if (errors.isNotEmpty) throw errors.first;

    final job = await _gateway.submit(project.toRequest());
    final updated = project.copyWith(
      lastJobId: job.id,
      lastJobStatus: job.status,
      lastFailureMessage: null,
      resultRelativePath: null,
      resultIsSynthetic: false,
      updatedAt: clock.now(),
    );
    await _projects.save(updated);
    return (updated, job);
  }

  /// Fetches the job status; persists the project only when something the
  /// user can see has changed.
  Future<(Project, GenerationJob)> refresh(Project project) async {
    final jobId = project.lastJobId;
    if (jobId == null) {
      throw const GenerationFailure('Генерация не запускалась.');
    }
    final job = await _gateway.getStatus(jobId);
    if (job.status == project.lastJobStatus) return (project, job);

    var updated = project.copyWith(
      lastJobStatus: job.status,
      lastFailureMessage: job.failure?.message,
      updatedAt: clock.now(),
    );
    if (job.status == GenerationStatus.succeeded) {
      final result = await _gateway.getResult(jobId);
      updated = updated.copyWith(
        // Remote results get downloaded in stage 6; the mock result is local.
        resultRelativePath: _storage.relativize(result.videoUri),
        resultIsSynthetic: result.isSynthetic,
      );
    }
    await _projects.save(updated);
    return (updated, job);
  }

  Future<(Project, GenerationJob)> cancel(Project project) async {
    final jobId = project.lastJobId;
    if (jobId == null) {
      throw const GenerationFailure('Генерация не запускалась.');
    }
    await _gateway.cancel(jobId);
    return refresh(project);
  }
}
