import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/media/media_asset.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/media/video_preview.dart';
import '../../../core/widgets/state_views.dart';
import '../application/job_tracker.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.projectId});

  final String projectId;

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(jobTrackerProvider(projectId).notifier)
        .start();
    if (!context.mounted) return;
    if (failure != null) {
      showFailure(context, failure);
      return;
    }
    context.pushReplacement(AppRoutes.projectProcessing(projectId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(jobTrackerProvider(projectId));
    final project = tracker.project;
    final theme = Theme.of(context);

    if (tracker.loading) {
      return const GlassScaffold(
        title: 'Результат',
        leading: GlassBackButton(),
        slivers: [],
      );
    }
    if (project == null || !project.hasResult) {
      return const GlassScaffold(
        title: 'Результат',
        leading: GlassBackButton(),
        slivers: [
          SliverToBoxAdapter(
            child: StateView(
              icon: Icons.movie_filter_outlined,
              title: 'Результата пока нет',
              message: 'Запустите генерацию на странице проекта.',
            ),
          ),
        ],
      );
    }

    final result = MediaAsset(
      id: 'result-${project.lastJobId}',
      kind: MediaKind.video,
      relativePath: project.resultRelativePath!,
      // The mock result is the source video, so its metadata applies.
      thumbnailRelativePath: project.resultIsSynthetic
          ? project.sourceVideo.thumbnailRelativePath
          : null,
      width: project.sourceVideo.width,
      height: project.sourceVideo.height,
      duration: project.resultIsSynthetic ? project.sourceVideo.duration : null,
    );

    final collapsed = 150 + MediaQuery.paddingOf(context).bottom;

    return GlassScaffold(
      title: 'Результат',
      leading: const GlassBackButton(),
      sheetCollapsedHeight: collapsed,
      sheet: GlassSheet(
        collapsedHeight: collapsed,
        expandedFraction: 0.55,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultBadge(synthetic: project.resultIsSynthetic),
            const SizedBox(height: AppSpacing.md),
            GlassButton(
              label: tracker.busy ? 'Запускаем…' : 'Сгенерировать ещё раз',
              icon: Icons.auto_awesome_rounded,
              prominent: true,
              expand: true,
              onPressed: tracker.busy ? null : () => _regenerate(context, ref),
            ),
          ],
        ),
        children: [
          if (project.resultIsSynthetic) ...[
            GlassSurface(
              child: const GlassRow(
                leading: Icon(Icons.info_outline_rounded),
                title: 'Это не AI-результат',
                subtitle:
                    'В демо-режиме вместо сгенерированного ролика '
                    'показывается ваше исходное видео без изменений.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SectionCaption('Запрос'),
          GlassSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              project.prompt.isEmpty
                  ? 'Без текстового описания'
                  : project.prompt,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Сохранение в галерею и «Поделиться» появятся в одном из '
            'следующих обновлений.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(
            child: VideoPreview(asset: result, maxHeight: 560),
          ),
        ),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.synthetic});

  final bool synthetic;

  @override
  Widget build(BuildContext context) {
    final color = synthetic ? AppColors.textSecondary : AppColors.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: color.withValues(alpha: 0.18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                synthetic ? Icons.science_outlined : Icons.auto_awesome,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  synthetic ? 'Тестовый результат, не AI' : 'Создано AI',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
