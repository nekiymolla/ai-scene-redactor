import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/media/media_tiles.dart';
import '../application/project_draft_controller.dart';

/// Step 4: summary, project name, rights and consent confirmation.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final _title = TextEditingController(
    text: ref.read(projectDraftProvider).title,
  );
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final (project, failure) = await ref
        .read(projectDraftProvider.notifier)
        .save();
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      showFailure(context, failure);
      return;
    }
    // Replaces the whole wizard stack; the draft is disposed afterwards.
    context.go(AppRoutes.project(project!.id));
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);
    final controller = ref.read(projectDraftProvider.notifier);
    final theme = Theme.of(context);
    final video = draft.sourceVideo;

    return GlassScaffold(
      subtitle: 'Шаг 4 из 4',
      title: 'Проверка',
      leading: const GlassBackButton(),
      bottomAction: GlassButton(
        label: _saving ? 'Сохраняем…' : 'Сохранить проект',
        icon: Icons.check_rounded,
        prominent: true,
        expand: true,
        onPressed: draft.canSave && !_saving ? _save : null,
      ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassTextField(
                  controller: _title,
                  label: 'Название проекта',
                  maxLength: 60,
                  errorText: draft.title.trim().isEmpty
                      ? 'Введите название'
                      : null,
                  onChanged: controller.setTitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionCaption('Материалы'),
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (video != null)
                        _SummaryRow(
                          title: 'Исходное видео',
                          value: video.duration == null
                              ? ''
                              : formatDuration(video.duration!),
                          media: [MediaThumbnail(asset: video, size: 64)],
                        ),
                      for (final c in draft.characters)
                        _SummaryRow(
                          title: c.label,
                          value: c.description.isEmpty
                              ? 'Фото: ${c.photos.length}'
                              : 'Вместо: ${c.description}',
                          media: [
                            for (final p in c.photos.take(3))
                              MediaThumbnail(asset: p, size: 48),
                          ],
                        ),
                      if (draft.styleReferences.isNotEmpty)
                        _SummaryRow(
                          title: 'Референсы стиля',
                          value: '${draft.styleReferences.length}',
                          media: [
                            for (final r in draft.styleReferences)
                              MediaThumbnail(asset: r, size: 48),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionCaption('Описание'),
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      draft.prompt.trim().isEmpty
                          ? 'Без текстового описания'
                          : draft.prompt.trim(),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Text(
                    'Качество ${draft.settings.resolution.label} · '
                    '${draft.settings.keepOriginalAudio ? 'с оригинальным звуком' : 'без оригинального звука'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionCaption('Обработка и права'),
                GlassSurface(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        const GlassRow(
                          leading: Icon(Icons.cloud_upload_outlined),
                          title: 'Файлы будут отправлены на обработку',
                          subtitle:
                              'При запуске генерации видео и фото уйдут на '
                              'наш сервер и внешней AI-модели.',
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: AppGlass.divider,
                        ),
                        CheckboxListTile.adaptive(
                          value: draft.consentGiven,
                          onChanged: (v) => controller.setConsent(v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                          title: Text(
                            'У меня есть права на видео и музыку, а люди '
                            'на фото согласны на их использование. Я не буду '
                            'выдавать результат за реальную съёмку.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'Проект сохранится на этом устройстве. Запуск генерации '
                    'появится в следующем обновлении приложения.',
                    style: theme.textTheme.bodySmall?.copyWith(
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
    required this.media,
  });

  final String title;
  final String value;
  final List<Widget> media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          for (final m in media) ...[const SizedBox(width: AppSpacing.xs), m],
        ],
      ),
    );
  }
}
