import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_controls.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../generation/domain/generation_request.dart';
import '../application/project_draft_controller.dart';

/// Step 3: the text prompt and generation settings.
class DescribeScreen extends ConsumerStatefulWidget {
  const DescribeScreen({super.key});

  static const examples = [
    'Перенеси действие в осенний лес',
    'Ночной неоновый город в стиле киберпанк',
    'Одень героев в средневековые костюмы',
    'Сохрани движения и ракурсы камеры',
  ];

  @override
  ConsumerState<DescribeScreen> createState() => _DescribeScreenState();
}

class _DescribeScreenState extends ConsumerState<DescribeScreen> {
  late final _prompt = TextEditingController(
    text: ref.read(projectDraftProvider).prompt,
  );

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  void _append(String example) {
    final current = _prompt.text.trim();
    final next = current.isEmpty ? example : '$current. $example';
    if (next.length > GenerationRequest.maxPromptLength) return;
    _prompt.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    ref.read(projectDraftProvider.notifier).setPrompt(next);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);
    final controller = ref.read(projectDraftProvider.notifier);
    final theme = Theme.of(context);
    final promptError = draft.validationErrors
        .where((f) => f.field == 'prompt')
        .map((f) => f.message)
        .firstOrNull;

    return GlassScaffold(
      subtitle: 'Шаг 3 из 4',
      title: 'Что изменить',
      leading: const GlassBackButton(),
      bottomAction: GlassButton(
        label: 'Далее',
        icon: Icons.arrow_forward_rounded,
        prominent: true,
        expand: true,
        onPressed: draft.describeStepDone
            ? () => context.push(AppRoutes.createReview)
            : null,
      ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassTextField(
                  controller: _prompt,
                  label: 'Описание трансформации',
                  hint: draft.characters.isEmpty
                      ? 'Опишите, что изменить: окружение, одежду, стиль…'
                      : 'Например: ${draft.characters.first.label} танцует '
                            'на крыше ночного города',
                  minLines: 4,
                  maxLines: 8,
                  maxLength: GenerationRequest.maxPromptLength,
                  // Only nag after the user has typed something.
                  errorText: _prompt.text.isEmpty ? null : promptError,
                  onChanged: controller.setPrompt,
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionCaption('Подсказки'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final e in DescribeScreen.examples)
                      GlassChip(label: e, onPressed: () => _append(e)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionCaption('Параметры'),
                GlassSurface(
                  child: Column(
                    children: [
                      GlassRow(
                        leading: const Icon(Icons.high_quality_outlined),
                        title: 'Качество',

                        trailing: SizedBox(
                          width: 150,
                          child: GlassSegmented<OutputResolution>(
                            values: OutputResolution.values,
                            selected: draft.settings.resolution,
                            labelOf: (r) => r.label,
                            onChanged: (r) => controller.setSettings(
                              draft.settings.copyWith(resolution: r),
                            ),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppGlass.divider,
                      ),
                      GlassRow(
                        leading: const Icon(Icons.music_note_outlined),
                        title: 'Оригинальный звук',
                        subtitle: 'Вернуть звук исходного видео в результат',
                        trailing: Switch.adaptive(
                          value: draft.settings.keepOriginalAudio,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => controller.setSettings(
                            draft.settings.copyWith(keepOriginalAudio: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'Сервер может снизить качество, если модель его не '
                    'поддерживает. AI может не сохранить мимику, точные '
                    'движения и монтаж — результат зависит от модели.',
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
