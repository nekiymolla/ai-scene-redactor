import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../projects/application/projects_providers.dart';
import '../../projects/domain/project.dart';
import '../domain/generation_job.dart';
import 'generation_providers.dart';

class JobTrackerState {
  const JobTrackerState({
    this.project,
    this.job,
    this.loading = true,
    this.busy = false,
    this.problem,
  });

  /// Null after loading means the project does not exist.
  final Project? project;

  /// Live job info; null until the first status arrives in this session.
  final GenerationJob? job;
  final bool loading;

  /// A start/cancel request is in flight.
  final bool busy;

  /// Last error talking to the backend. For [NetworkFailure] polling keeps
  /// retrying in the background.
  final AppFailure? problem;

  GenerationStatus? get status => job?.status ?? project?.lastJobStatus;

  bool get isRunning => project?.hasActiveJob ?? false;

  JobTrackerState copyWith({
    Project? project,
    GenerationJob? job,
    bool? loading,
    bool? busy,
    AppFailure? problem,
    bool clearProblem = false,
  }) {
    return JobTrackerState(
      project: project ?? this.project,
      job: job ?? this.job,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      problem: clearProblem ? null : problem ?? this.problem,
    );
  }
}

/// Follows one project's generation job while any screen shows it.
///
/// Polls until the job reaches a terminal status. On network errors it keeps
/// retrying with exponential backoff (up to 10 s). Polling stops when no
/// widget watches the tracker; it resumes from the persisted job id the next
/// time the project is opened, including after an app restart.
class JobTracker extends Notifier<JobTrackerState> {
  JobTracker(this.projectId);

  final String projectId;

  static const _maxBackoff = Duration(seconds: 10);

  Timer? _timer;
  var _delay = Duration.zero;

  @override
  JobTrackerState build() {
    ref.onDispose(() => _timer?.cancel());
    _load();
    return const JobTrackerState();
  }

  Future<void> _load() async {
    try {
      final project = await ref
          .read(projectsRepositoryProvider)
          .byId(projectId);
      if (!ref.mounted) return;
      state = JobTrackerState(project: project, loading: false);
      if (project?.hasActiveJob ?? false) _schedule(Duration.zero);
    } on AppFailure catch (f) {
      if (ref.mounted) state = JobTrackerState(loading: false, problem: f);
    }
  }

  /// Starts a new job (also used for "try again").
  Future<AppFailure?> start() async {
    final project = state.project;
    if (project == null || state.busy || project.hasActiveJob) return null;
    state = state.copyWith(busy: true, clearProblem: true);
    try {
      final (updated, job) = await ref
          .read(generationServiceProvider)
          .start(project);
      if (!ref.mounted) return null;
      state = JobTrackerState(project: updated, job: job, loading: false);
      _invalidateLists();
      _schedule(ref.read(pollIntervalProvider));
      return null;
    } on AppFailure catch (f) {
      if (ref.mounted) state = state.copyWith(busy: false, problem: f);
      return f;
    }
  }

  Future<AppFailure?> cancel() async {
    final project = state.project;
    if (project == null || state.busy || !project.hasActiveJob) return null;
    state = state.copyWith(busy: true);
    try {
      final (updated, job) = await ref
          .read(generationServiceProvider)
          .cancel(project);
      if (!ref.mounted) return null;
      _timer?.cancel();
      state = JobTrackerState(project: updated, job: job, loading: false);
      _invalidateLists();
      return null;
    } on AppFailure catch (f) {
      if (ref.mounted) state = state.copyWith(busy: false, problem: f);
      return f;
    }
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _poll);
  }

  Future<void> _poll() async {
    final project = state.project;
    if (!ref.mounted || project == null || !project.hasActiveJob) return;
    final interval = ref.read(pollIntervalProvider);
    try {
      final before = project.lastJobStatus;
      final (updated, job) = await ref
          .read(generationServiceProvider)
          .refresh(project);
      if (!ref.mounted) return;
      state = state.copyWith(project: updated, job: job, clearProblem: true);
      if (updated.lastJobStatus != before) _invalidateLists();
      _delay = interval;
      if (!job.status.isTerminal) _schedule(interval);
    } on NetworkFailure catch (f) {
      if (!ref.mounted) return;
      state = state.copyWith(problem: f);
      _delay = _delay <= interval ? interval * 2 : _delay * 2;
      if (_delay > _maxBackoff) _delay = _maxBackoff;
      _schedule(_delay);
    } on AppFailure catch (f) {
      // Not retryable automatically (e.g. the job is gone): stop and show.
      if (ref.mounted) state = state.copyWith(problem: f);
    }
  }

  void _invalidateLists() {
    ref
      ..invalidate(recentProjectsProvider)
      ..invalidate(projectProvider(projectId));
  }
}

final jobTrackerProvider = NotifierProvider.autoDispose
    .family<JobTracker, JobTrackerState, String>(JobTracker.new);
