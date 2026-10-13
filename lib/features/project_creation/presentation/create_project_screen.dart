import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_limits.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/media/media_tiles.dart';
import '../../../core/widgets/media/video_preview.dart';
import '../../generation/domain/generation_request.dart';
import '../application/project_draft.dart';
import '../application/project_draft_controller.dart';

/// Step 1: the source video and optional style references.
class CreateProjectScreen extends ConsumerWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(projectDraftProvider);
    final controller = ref.read(projectDraftProvider.notifier);

    Future<void> run(Future<AppFailure?> Function() action) async {
      final failure = await action();
      if (failure != null && context.mounted) showFailure(context, failure);
    }

    return GlassScaffold(
      subtitle: 'Шаг 1 из 4',
      title: 'Исходное видео',
      leading: const GlassBackButton(),
      bottomAction: GlassButton(
        label: 'Далее',
        icon: Icons.arrow_forward_rounded,
        prominent: true,
        expand: true,
        onPressed: draft.mediaStepDone
            ? () => context.push(AppRoutes.createCharacters)
            : null,
      ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(
            child: draft.sourceVideo == null
                ? _PickVideoCard(
                    busy: draft.importing is SourceVideoSlot,
                    onPick: () => run(controller.pickSourceVideo),
                  )
                : _SelectedVideo(
                    draft: draft,
                    onReplace: () => run(controller.pickSourceVideo),
                    onRemove: controller.removeSourceVideo,
                  ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.page.copyWith(top: AppSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionCaption('Референсы стиля · необязательно'),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    'Фото или видео с желаемым окружением, атмосферой или '
                    'стилем. Например, кадр леса или неонового города.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final asset in draft.styleReferences)
                      MediaThumbnail(
                        asset: asset,
                        onRemove: () =>
                            controller.removeStyleReference(asset.id),
                        removeLabel: 'Удалить референс',
                      ),
                    if (draft.canAddStyleReference)
                      AddMediaTile(
                        label: 'Добавить',
                        busy: draft.importing is StyleReferenceSlot,
                        onTap: draft.isBusy
                            ? null
                            : () => run(controller.addStyleReference),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Text(
                    'До ${GenerationRequest.maxStyleReferences} референсов.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickVideoCard extends StatelessWidget {
  const _PickVideoCard({required this.busy, required this.onPick});

  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const limits = VideoLimits.source;
    return Semantics(
      button: true,
      label: 'Выбрать видео из галереи',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: busy ? null : onPick,
        child: GlassSurface(
          shape: const RoundedSuperellipseBorder(borderRadius: AppRadii.hero),
          child: SizedBox(
            height: 300,
            child: Center(
              child: busy
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppSpacing.md),
                        Text('Подготавливаем видео…'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: AppColors.accentGradient.createShader,
                          child: const Icon(
                            Icons.video_library_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Выбрать видео из галереи',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${limits.minDuration.inSeconds}–'
                          '${limits.maxDuration.inSeconds} секунд, '
                          'до ${limits.maxBytes ~/ (1024 * 1024)} МБ',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedVideo extends StatelessWidget {
  const _SelectedVideo({
    required this.draft,
    required this.onReplace,
    required this.onRemove,
  });

  final ProjectDraft draft;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final video = draft.sourceVideo!;
    final busy = draft.importing is SourceVideoSlot;
    final details = [
      if (video.duration != null) formatDuration(video.duration!),
      if (video.width != null && video.height != null)
        '${video.width}×${video.height}',
      if (video.sizeBytes != null) formatBytes(video.sizeBytes!),
    ].join(' · ');

    return Column(
      children: [
        VideoPreview(asset: video),
        const SizedBox(height: AppSpacing.sm),
        Text(details, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: busy ? 'Загрузка…' : 'Заменить',
                icon: Icons.swap_horiz_rounded,
                expand: true,
                onPressed: draft.isBusy ? null : onReplace,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassButton(
                label: 'Удалить',
                icon: Icons.delete_outline_rounded,
                expand: true,
                onPressed: draft.isBusy ? null : onRemove,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
