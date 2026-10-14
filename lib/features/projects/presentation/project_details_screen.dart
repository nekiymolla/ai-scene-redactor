import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/media/media_tiles.dart';
import '../../../core/widgets/media/video_preview.dart';
import '../../../core/widgets/state_views.dart';
import '../../generation/application/job_tracker.dart';
import '../../generation/domain/generation_job.dart';
import '../application/projects_providers.dart';
import '../domain/project.dart';
import 'project_status.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final String projectId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Удалить проект?',
      message: 'Видео и фото этого проекта будут удалены с устройства.',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(deleteProjectProvider)(projectId);
      if (context.mounted) context.go(AppRoutes.home);
    } on AppFailure catch (f) {
      if (context.mounted) showFailure(context, f);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));

    return project.when(
      loading: () => const GlassScaffold(
        title: '',
        leading: GlassBackButton(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (_, _) => _missing('Не удалось открыть проект'),
      data: (p) => p == null
          ? _missing('Проект не найден')
          : GlassScaffold(
              title: p.title,
              leading: const GlassBackButton(),
              actions: [
                GlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Удалить проект',
                  onPressed: () => _delete(context, ref),
                ),
              ],
              bottomAction: _PrimaryAction(projectId: projectId),
              slivers: [_Body(project: p)],
            ),
    );
  }

  Widget _missing(String title) => GlassScaffold(
    title: '',
    leading: const GlassBackButton(),
    slivers: [
      SliverToBoxAdapter(
        child: StateView(
          icon: Icons.folder_off_outlined,
          title: title,
          message: 'Возможно, он был удалён.',
        ),
      ),
    ],
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = project;
    return SliverPadding(
      padding: AppSpacing.page,
      sliver: SliverList.list(
        children: [
          Row(
            children: [
              _LiveStatusChip(projectId: p.id),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Создан ${formatDate(p.createdAt)}',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          VideoPreview(asset: p.sourceVideo),
          const SizedBox(height: AppSpacing.lg),
          _GenerationCard(projectId: p.id),
          const SectionCaption('Описание'),
          GlassSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                p.prompt.isEmpty ? 'Без текстового описания' : p.prompt,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          if (p.characters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionCaption('Персонажи'),
            for (final c in p.characters) ...[
              GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.label, style: theme.textTheme.titleMedium),
                    if (c.description.isNotEmpty)
                      Text(
                        'Вместо: ${c.description}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final photo in c.photos)
                          MediaThumbnail(asset: photo, size: 64),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (p.styleReferences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionCaption('Референсы стиля'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in p.styleReferences) MediaThumbnail(asset: r),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionCaption('Параметры'),
          GlassSurface(
            child: Column(
              children: [
                GlassRow(
                  leading: const Icon(Icons.high_quality_outlined),
                  title: 'Качество',
                  trailing: Text(
                    p.settings.resolution.label,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppGlass.divider),
                GlassRow(
                  leading: const Icon(Icons.music_note_outlined),
                  title: 'Оригинальный звук',
                  trailing: Text(
                    p.settings.keepOriginalAudio ? 'Да' : 'Нет',
                    style: theme.textTheme.bodyLarge,
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

class _LiveStatusChip extends ConsumerWidget {
  const _LiveStatusChip({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      jobTrackerProvider(projectId).select((t) => t.status),
    );
    return ProjectStatusChip(status: status);
  }
}

/// Shows the state of the latest generation and links to its screen.
class _GenerationCard extends ConsumerWidget {
  const _GenerationCard({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(jobTrackerProvider(projectId));
    final project = tracker.project;
    if (tracker.loading || project == null) return const SizedBox.shrink();

    final job = tracker.job;
    final (icon, title, subtitle, route) = switch (tracker.status) {
      null => (null, null, null, null),
      GenerationStatus.uploading ||
      GenerationStatus.queued ||
      GenerationStatus.processing => (
        Icons.auto_awesome_rounded,
        job?.progress != null && tracker.status == GenerationStatus.processing
            ? 'Идёт обработка · ${(job!.progress! * 100).round()}%'
            : 'Идёт обработка',
        job?.statusMessage ?? 'Обновляем статус…',
        AppRoutes.projectProcessing(projectId),
      ),
      GenerationStatus.succeeded => (
        Icons.check_circle_outline_rounded,
        'Видео готово',
        project.resultIsSynthetic
            ? 'Тестовый результат, не AI'
            : 'Откройте, чтобы посмотреть',
        AppRoutes.projectResult(projectId),
      ),
      GenerationStatus.failed => (
        Icons.error_outline_rounded,
        'Не получилось',
        project.lastFailureMessage ?? 'Попробуйте ещё раз.',
        null,
      ),
      GenerationStatus.cancelled => (
        Icons.stop_circle_outlined,
        'Генерация отменена',
        'Можно запустить заново.',
        null,
      ),
    };
    if (title == null) return const SizedBox.shrink();

    final row = GlassRow(
      leading: Icon(icon),
      title: title,
      subtitle: subtitle,
      trailing: route == null
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: route == null ? null : () => context.push(route),
        child: GlassSurface(child: row),
      ),
    );
  }
}

class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.projectId});

  final String projectId;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(jobTrackerProvider(projectId).notifier)
        .start();
    if (!context.mounted) return;
    if (failure != null) {
      showFailure(context, failure);
      return;
    }
    context.push(AppRoutes.projectProcessing(projectId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(jobTrackerProvider(projectId));
    final project = tracker.project;
    if (tracker.loading || project == null) return const SizedBox.shrink();

    if (project.hasActiveJob) {
      return GlassButton(
        label: 'Смотреть прогресс',
        icon: Icons.hourglass_top_rounded,
        prominent: true,
        expand: true,
        onPressed: () => context.push(AppRoutes.projectProcessing(projectId)),
      );
    }
    if (project.hasResult) {
      return GlassButton(
        label: 'Смотреть результат',
        icon: Icons.play_circle_outline_rounded,
        prominent: true,
        expand: true,
        onPressed: () => context.push(AppRoutes.projectResult(projectId)),
      );
    }
    final failed =
        tracker.status == GenerationStatus.failed ||
        tracker.status == GenerationStatus.cancelled;
    return GlassButton(
      label: tracker.busy
          ? 'Запускаем…'
          : failed
          ? 'Попробовать снова'
          : 'Создать видео',
      icon: failed ? Icons.refresh_rounded : Icons.auto_awesome_rounded,
      prominent: true,
      expand: true,
      onPressed: tracker.busy ? null : () => _start(context, ref),
    );
  }
}
