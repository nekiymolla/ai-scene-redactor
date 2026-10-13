import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/media/media_limits.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_buttons.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/media/media_tiles.dart';
import '../../generation/domain/generation_request.dart';
import '../application/project_draft.dart';
import '../application/project_draft_controller.dart';

/// Step 2: who should appear instead of whom. Manual mapping: the user
/// describes the person in the source video; automatic detection is post-MVP.
class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(projectDraftProvider);
    final controller = ref.read(projectDraftProvider.notifier);
    final theme = Theme.of(context);

    return GlassScaffold(
      subtitle: 'Шаг 2 из 4',
      title: 'Персонажи',
      leading: const GlassBackButton(),
      bottomAction: GlassButton(
        label: draft.characters.isEmpty ? 'Пропустить' : 'Далее',
        icon: Icons.arrow_forward_rounded,
        prominent: true,
        expand: true,
        onPressed: draft.charactersStepDone
            ? () => context.push(AppRoutes.createDescribe)
            : null,
      ),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page.copyWith(bottom: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Добавьте людей, которые появятся в видео вместо оригинальных '
              'персонажей. Лучше всего работают чёткие фото лица и фото в '
              'полный рост. Можно пропустить, если меняете только '
              'окружение или стиль.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverList.separated(
            itemCount: draft.characters.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _CharacterCard(
              key: ValueKey(draft.characters[i].id),
              character: draft.characters[i],
              draft: draft,
            ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.page.copyWith(top: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: draft.canAddCharacter
                ? GlassButton(
                    label: 'Добавить персонажа',
                    icon: Icons.person_add_alt_1_rounded,
                    expand: true,
                    onPressed: draft.isBusy ? null : controller.addCharacter,
                  )
                : Text(
                    'Максимум ${GenerationRequest.maxCharacters} персонажа.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ),
      ],
    );
  }
}

class _CharacterCard extends ConsumerStatefulWidget {
  const _CharacterCard({
    super.key,
    required this.character,
    required this.draft,
  });

  final CharacterReference character;
  final ProjectDraft draft;

  @override
  ConsumerState<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends ConsumerState<_CharacterCard> {
  late final _label = TextEditingController(text: widget.character.label);
  late final _description = TextEditingController(
    text: widget.character.description,
  );

  @override
  void dispose() {
    _label.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final failure = await ref
        .read(projectDraftProvider.notifier)
        .addCharacterPhotos(widget.character.id);
    if (failure != null && mounted) showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(projectDraftProvider.notifier);
    final character = widget.character;
    final draft = widget.draft;
    final theme = Theme.of(context);
    final busyHere = draft.importing == CharacterPhotoSlot(character.id);
    final canAddPhoto =
        character.photos.length < GenerationRequest.maxPhotosPerCharacter;
    final labelMissing = character.label.trim().isEmpty;

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _label,
                  onChanged: (v) =>
                      controller.updateCharacter(character.id, label: v),
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    errorText: labelMissing ? 'Укажите имя' : null,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Удалить персонажа',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: draft.isBusy
                    ? null
                    : () => controller.removeCharacter(character.id),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md, color: AppGlass.divider),
          TextField(
            controller: _description,
            onChanged: (v) =>
                controller.updateCharacter(character.id, description: v),
            minLines: 1,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Кого заменить в видео',
              hintText: 'Например: мужчина в чёрном костюме справа',
              border: InputBorder.none,
              isDense: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final photo in character.photos)
                MediaThumbnail(
                  asset: photo,
                  size: 72,
                  onRemove: () =>
                      controller.removeCharacterPhoto(character.id, photo.id),
                  removeLabel: 'Удалить фото',
                ),
              if (canAddPhoto)
                AddMediaTile(
                  label: 'Фото',
                  icon: Icons.add_a_photo_outlined,
                  size: 72,
                  busy: busyHere,
                  onTap: draft.isBusy ? null : _addPhotos,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            character.photos.isEmpty
                ? 'Добавьте хотя бы одно фото (минимум '
                      '${ImageLimits.minSide}×${ImageLimits.minSide}).'
                : 'Фото: ${character.photos.length} из '
                      '${GenerationRequest.maxPhotosPerCharacter}. '
                      'Первое — основное, остальные — другие ракурсы.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: character.photos.isEmpty
                  ? theme.colorScheme.error
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
