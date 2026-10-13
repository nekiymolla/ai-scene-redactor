import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_asset.dart';

/// A person who should appear in the result instead of someone in the
/// source video. Providers that support multi-angle references use all
/// [photos]; others use only the first one.
class CharacterReference {
  const CharacterReference({
    required this.id,
    required this.label,
    this.description = '',
    this.photos = const [],
  });

  final String id;

  /// Human-readable name, e.g. "Аня". Used in the prompt and UI.
  final String label;

  /// Who to replace in the source video, e.g. "девушка в красном слева".
  /// Manual stand-in for automatic character detection (post-MVP).
  final String description;
  final List<MediaAsset> photos;

  CharacterReference copyWith({
    String? label,
    String? description,
    List<MediaAsset>? photos,
  }) {
    return CharacterReference(
      id: id,
      label: label ?? this.label,
      description: description ?? this.description,
      photos: photos ?? this.photos,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'description': description,
    'photos': [for (final p in photos) p.toJson()],
  };

  factory CharacterReference.fromJson(Map<String, Object?> json) {
    return CharacterReference(
      id: json['id']! as String,
      label: json['label']! as String,
      description: json['description'] as String? ?? '',
      photos: [
        for (final p in json['photos']! as List)
          MediaAsset.fromJson((p as Map).cast()),
      ],
    );
  }
}

enum OutputResolution {
  p480('480p'),
  p720('720p');

  const OutputResolution(this.label);

  final String label;
}

class GenerationSettings {
  const GenerationSettings({
    this.resolution = OutputResolution.p480,
    this.keepOriginalAudio = true,
  });

  /// The backend may lower it if the selected provider cannot do better.
  final OutputResolution resolution;

  /// Re-attach the source audio track to the result. Done by the backend
  /// with ffmpeg when the provider does not preserve audio itself.
  final bool keepOriginalAudio;

  GenerationSettings copyWith({
    OutputResolution? resolution,
    bool? keepOriginalAudio,
  }) {
    return GenerationSettings(
      resolution: resolution ?? this.resolution,
      keepOriginalAudio: keepOriginalAudio ?? this.keepOriginalAudio,
    );
  }

  Map<String, Object?> toJson() => {
    'resolution': resolution.name,
    'keepOriginalAudio': keepOriginalAudio,
  };

  factory GenerationSettings.fromJson(Map<String, Object?> json) {
    return GenerationSettings(
      resolution: OutputResolution.values.byName(
        json['resolution'] as String? ?? OutputResolution.p480.name,
      ),
      keepOriginalAudio: json['keepOriginalAudio'] as bool? ?? true,
    );
  }
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
      for (final c in characters) ...[
        if (c.label.trim().isEmpty)
          const ValidationFailure(
            'У каждого персонажа должно быть имя.',
            field: 'characters',
          ),
        if (c.photos.isEmpty || c.photos.length > maxPhotosPerCharacter)
          ValidationFailure(
            'Для «${c.label.trim().isEmpty ? 'персонажа' : c.label.trim()}» '
            'нужно от 1 до $maxPhotosPerCharacter фото.',
            field: 'characters',
          ),
      ],
      if (styleReferences.length > maxStyleReferences)
        const ValidationFailure(
          'Можно добавить не больше $maxStyleReferences референсов стиля.',
          field: 'styleReferences',
        ),
    ];
  }
}
