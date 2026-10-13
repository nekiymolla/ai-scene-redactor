import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/state_views.dart';
import '../../generation/domain/generation_job.dart';
import '../../projects/application/projects_providers.dart';
import '../../projects/domain/project.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(recentProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Scene Changer'),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppSpacing.page.copyWith(top: AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: _CreateCard(
                  onCreate: () => context.push(AppRoutes.create),
                ),
              ),
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
                          itemBuilder: (_, i) =>
                              _ProjectTile(project: items[i]),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: AppRadii.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.onAccent, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Преобразите любое видео',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Замените персонажей, одежду и окружение с помощью AI.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Новое видео'),
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
    final status = project.lastJobStatus;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.movie_outlined),
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          status == null ? 'Черновик' : _statusLabel(status),
          maxLines: 1,
        ),
      ),
    );
  }
}

String _statusLabel(GenerationStatus status) => switch (status) {
  GenerationStatus.uploading => 'Загрузка',
  GenerationStatus.queued => 'В очереди',
  GenerationStatus.processing => 'Обработка',
  GenerationStatus.succeeded => 'Готово',
  GenerationStatus.failed => 'Ошибка',
  GenerationStatus.cancelled => 'Отменено',
};
