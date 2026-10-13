import '../../../core/errors/app_failure.dart';
import 'media_asset.dart';

/// A person who should appear in the result instead of someone in the
/// source video. Providers that support multi-angle references use all
/// [photos]; others use only the first one.
class CharacterReference {
  const CharacterReference({
    required this.id,
    required this.label,
    required this.photos,
  });

  final String id;

  /// Human-readable name, e.g. "Главный герой". Used in the prompt and UI.
  final String label;
  final List<MediaAsset> photos;
}

enum OutputResolution { p480, p720 }

class GenerationSettings {
  const GenerationSettings({
    this.resolution = OutputResolution.p480,
    this.keepOriginalAudio = true,
  });

  final OutputResolution resolution;

  /// Re-attach the source audio track to the result. Done by the backend
  /// with ffmpeg when the provider does not preserve audio itself.
  final bool keepOriginalAudio;
}

/// Everything the user prepared for one generation.
class GenerationRequest {
  const GenerationRequest({
    required this.sourceVideo,
    required this.prompt,
    this.characters = const [],
    this.styleReferences = const [],
    this.settings = const GenerationSettings(),
  });

  /// Client-side limits. The backend re-validates against the limits of the
  /// selected provider, which may be stricter.
  static const maxPromptLength = 2000;
  static const maxCharacters = 4;
  static const maxPhotosPerCharacter = 4;
  static const maxStyleReferences = 2;

  final MediaAsset sourceVideo;
  final String prompt;
  final List<CharacterReference> characters;

  /// Images or videos describing the desired environment, mood or style.
  final List<MediaAsset> styleReferences;
  final GenerationSettings settings;

  /// Returns every problem at once so the form can highlight all fields.
  List<ValidationFailure> validate() {
    final trimmed = prompt.trim();
    return [
      if (!sourceVideo.isVideo)
        const ValidationFailure(
          'Исходный файл должен быть видео.',
          field: 'sourceVideo',
        ),
      if (trimmed.isEmpty && characters.isEmpty)
        const ValidationFailure(
          'Опишите изменения или добавьте хотя бы одного персонажа.',
          field: 'prompt',
        ),
      if (trimmed.length > maxPromptLength)
        const ValidationFailure(
          'Описание слишком длинное (максимум $maxPromptLength символов).',
          field: 'prompt',
        ),
      if (characters.length > maxCharacters)
        const ValidationFailure(
          'Можно заменить не больше $maxCharacters персонажей.',
          field: 'characters',
        ),
      for (final c in characters)
        if (c.photos.isEmpty || c.photos.length > maxPhotosPerCharacter)
          ValidationFailure(
            'Для «${c.label}» нужно от 1 до $maxPhotosPerCharacter фото.',
            field: 'characters',
          ),
      if (styleReferences.length > maxStyleReferences)
        const ValidationFailure(
          'Можно добавить не больше $maxStyleReferences референсов стиля.',
          field: 'styleReferences',
        ),
    ];
  }
}
