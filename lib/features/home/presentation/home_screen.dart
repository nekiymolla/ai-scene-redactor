import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/media/media_tiles.dart';
import '../../projects/application/projects_providers.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/project_status.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(recentProjectsProvider);

    return GlassScaffold(
      title: 'AI Scene Changer',
      actions: [
        GlassIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Настройки',
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
      bottomAction: GlassButton(
        label: 'Новое видео',
        icon: Icons.add_rounded,
        prominent: true,
        expand: true,
        onPressed: () => context.push(AppRoutes.create),
      ),
      slivers: [
        const SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(child: _IntroCard()),
        ),
        SliverPadding(
          padding: AppSpacing.page.copyWith(
            top: AppSpacing.xl,
            bottom: AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Недавние проекты',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        ...projects.when(
          loading: () => const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
          error: (_, _) => [
            SliverToBoxAdapter(
              child: StateView(
                icon: Icons.error_outline,
                title: 'Не удалось загрузить проекты',
                actionLabel: 'Повторить',
                onAction: () => ref.invalidate(recentProjectsProvider),
              ),
            ),
          ],
          data: (items) => items.isEmpty
              ? const [
                  SliverToBoxAdapter(
                    child: StateView(
                      icon: Icons.movie_filter_outlined,
                      title: 'Пока нет проектов',
                      message:
                          'Создайте первое видео — проекты будут храниться только на этом устройстве.',
                    ),
                  ),
                ]
              : [
                  SliverPadding(
                    padding: AppSpacing.page,
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _ProjectTile(project: items[i]),
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      shape: const RoundedSuperellipseBorder(borderRadius: AppRadii.hero),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: AppColors.accentGradient.createShader,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Преобразите любое видео', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Замените персонажей, одежду и окружение с помощью AI — '
            'движение и звук исходника по возможности сохранятся.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AppRoutes.project(project.id)),
        child: GlassSurface(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              MediaThumbnail(asset: project.sourceVideo, size: 72),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      project.prompt.isEmpty
                          ? formatShortDateTime(project.updatedAt)
                          : project.prompt,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ProjectStatusChip(status: project.lastJobStatus),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
