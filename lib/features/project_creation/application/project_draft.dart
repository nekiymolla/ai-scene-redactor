import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_asset.dart';
import '../../generation/domain/generation_request.dart';
import '../../projects/domain/project.dart';

/// Which part of the form is currently importing media, so the spinner shows
/// in the right place and actions are blocked meanwhile.
sealed class ImportSlot {
  const ImportSlot();
}

final class SourceVideoSlot extends ImportSlot {
  const SourceVideoSlot();
}

final class StyleReferenceSlot extends ImportSlot {
  const StyleReferenceSlot();
}

final class CharacterPhotoSlot extends ImportSlot {
  const CharacterPhotoSlot(this.characterId);

  final String characterId;

  @override
  bool operator ==(Object other) =>
      other is CharacterPhotoSlot && other.characterId == characterId;

  @override
  int get hashCode => characterId.hashCode;
}

/// The project being assembled in the creation wizard.
class ProjectDraft {
  const ProjectDraft({
    required this.projectId,
    required this.createdAt,
    required this.title,
    this.sourceVideo,
    this.characters = const [],
    this.styleReferences = const [],
    this.prompt = '',
    this.settings = const GenerationSettings(),
    this.consentGiven = false,
    this.importing,
  });

  final String projectId;
  final DateTime createdAt;
  final String title;
  final MediaAsset? sourceVideo;
  final List<CharacterReference> characters;
  final List<MediaAsset> styleReferences;
  final String prompt;
  final GenerationSettings settings;

  /// Rights and consent confirmation from the review step.
  final bool consentGiven;
  final ImportSlot? importing;

  bool get isBusy => importing != null;

  bool get canAddCharacter =>
      characters.length < GenerationRequest.maxCharacters;

  bool get canAddStyleReference =>
      styleReferences.length < GenerationRequest.maxStyleReferences;

  // Step guards for the wizard.
  bool get mediaStepDone => sourceVideo != null && !isBusy;

  bool get charactersStepDone =>
      !isBusy &&
      characters.every((c) => c.label.trim().isNotEmpty && c.photos.isNotEmpty);

  bool get describeStepDone => !isBusy && validationErrors.isEmpty;

  bool get canSave =>
      describeStepDone && consentGiven && title.trim().isNotEmpty;

  GenerationRequest? get request {
    final video = sourceVideo;
    if (video == null) return null;
    return GenerationRequest(
      sourceVideo: video,
      prompt: prompt,
      characters: characters,
      styleReferences: styleReferences,
      settings: settings,
    );
  }

  List<ValidationFailure> get validationErrors =>
      request?.validate() ??
      const [
        ValidationFailure('Выберите исходное видео.', field: 'sourceVideo'),
      ];

  Project toProject(DateTime now) {
    return Project(
      id: projectId,
      title: title.trim(),
      createdAt: createdAt,
      updatedAt: now,
      sourceVideo: sourceVideo!,
      characters: [
        for (final c in characters)
          c.copyWith(label: c.label.trim(), description: c.description.trim()),
      ],
      styleReferences: styleReferences,
      prompt: prompt.trim(),
      settings: settings,
    );
  }

  ProjectDraft copyWith({
    String? title,
    MediaAsset? sourceVideo,
    bool clearSourceVideo = false,
    List<CharacterReference>? characters,
    List<MediaAsset>? styleReferences,
    String? prompt,
    GenerationSettings? settings,
    bool? consentGiven,
    ImportSlot? importing,
    bool clearImporting = false,
  }) {
    return ProjectDraft(
      projectId: projectId,
      createdAt: createdAt,
      title: title ?? this.title,
      sourceVideo: clearSourceVideo ? null : sourceVideo ?? this.sourceVideo,
      characters: characters ?? this.characters,
      styleReferences: styleReferences ?? this.styleReferences,
      prompt: prompt ?? this.prompt,
      settings: settings ?? this.settings,
      consentGiven: consentGiven ?? this.consentGiven,
      importing: clearImporting ? null : importing ?? this.importing,
    );
  }
}
