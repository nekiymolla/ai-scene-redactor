import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/state_views.dart';
import '../application/job_tracker.dart';
import '../domain/generation_job.dart';
import 'progress_ring.dart';

/// Live status of a project's generation job. Leaving the screen does not
/// stop the job; reopening the project resumes tracking.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  var _navigated = false;

  Future<void> _cancel() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Отменить генерацию?',
      message: 'Обработку придётся запускать заново.',
      confirmLabel: 'Отменить генерацию',
    );
    if (!confirmed || !mounted) return;
    final failure = await ref
        .read(jobTrackerProvider(widget.projectId).notifier)
        .cancel();
    if (failure != null && mounted) showFailure(context, failure);
  }

  Future<void> _retry() async {
    final failure = await ref
        .read(jobTrackerProvider(widget.projectId).notifier)
        .start();
    if (failure != null && mounted) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final provider = jobTrackerProvider(widget.projectId);
    final tracker = ref.watch(provider);

    // Open the result as soon as the job succeeds.
    ref.listen(provider, (previous, next) {
      if (_navigated) return;
      if (previous?.project?.hasResult != true &&
          (next.project?.hasResult ?? false)) {
        _navigated = true;
        context.pushReplacement(AppRoutes.projectResult(widget.projectId));
      }
    });

    final status = tracker.status;
    final Widget body;
    if (tracker.loading) {
      body = const SizedBox(height: 300);
    } else if (tracker.project == null) {
      body = const StateView(
        icon: Icons.folder_off_outlined,
        title: 'Проект не найден',
      );
    } else if (status == GenerationStatus.failed) {
      body = _Failed(
        message:
            tracker.project!.lastFailureMessage ??
            'Не удалось создать видео. Попробуйте ещё раз.',
      );
    } else if (status == GenerationStatus.cancelled) {
      body = const StateView(
        icon: Icons.stop_circle_outlined,
        title: 'Генерация отменена',
        message: 'Можно запустить её заново в любой момент.',
      );
    } else {
      body = _Running(tracker: tracker);
    }

    final project = tracker.project;
    final terminal = status?.isTerminal ?? false;

    return GlassScaffold(
      title: switch (status) {
        GenerationStatus.failed => 'Ошибка генерации',
        GenerationStatus.cancelled => 'Отменено',
        _ => 'Создаём видео',
      },
      leading: const GlassBackButton(),
      bottomAction: project == null || tracker.loading
          ? null
          : terminal
          ? (status == GenerationStatus.succeeded
                ? null
                : GlassButton(
                    label: tracker.busy ? 'Запускаем…' : 'Попробовать снова',
                    icon: Icons.refresh_rounded,
                    prominent: true,
                    expand: true,
                    onPressed: tracker.busy ? null : _retry,
                  ))
          : GlassButton(
              label: 'Отменить',
              icon: Icons.close_rounded,
              expand: true,
              onPressed: tracker.busy ? null : _cancel,
            ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(child: body),
        ),
        if (tracker.job?.isSynthetic ?? true)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _DemoNotice()),
          ),
      ],
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.tracker});

  final JobTrackerState tracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = tracker.job;
    final status = tracker.status ?? GenerationStatus.uploading;
    final progress = status == GenerationStatus.processing
        ? job?.progress
        : null;
    final remaining = job?.estimatedRemaining;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        ProgressRing(
          progress: progress,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                progress == null ? '…' : '${(progress * 100).round()}%',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (remaining != null)
                Text(
                  'осталось ~${_formatRemaining(remaining)}',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          job?.statusMessage ?? 'Подготавливаем задачу',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Steps(status: status),
        if (tracker.problem != null) ...[
          const SizedBox(height: AppSpacing.md),
          GlassSurface(
            child: GlassRow(
              leading: const Icon(Icons.wifi_off_rounded),
              title: tracker.problem is NetworkFailure
                  ? 'Нет соединения — пробуем снова'
                  : 'Не удалось обновить статус',
              subtitle: tracker.problem!.message,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Можно свернуть приложение или вернуться к проекту — обработка '
          'продолжится.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _formatRemaining(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds + 1} с';
    return '${(d.inSeconds / 60).ceil()} мин';
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.status});

  final GenerationStatus status;

  static const _steps = [
    (GenerationStatus.uploading, 'Загрузка'),
    (GenerationStatus.queued, 'Очередь'),
    (GenerationStatus.processing, 'Генерация'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = status.index;
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          for (final (s, label) in _steps)
            Expanded(
              child: Column(
                children: [
                  Icon(
                    s.index < current
                        ? Icons.check_circle_rounded
                        : s.index == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: s.index <= current
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: s.index <= current
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: StateView(
        icon: Icons.error_outline_rounded,
        title: 'Не получилось',
        message: message,
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.science_outlined,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Демо-режим: настоящая AI-обработка не выполняется, этапы '
            'и время имитируются.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
