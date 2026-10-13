import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/media/media_asset.dart';
import '../../../core/media/media_importer.dart';
import '../../../core/media/media_limits.dart';
import '../../../core/media/media_picker.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../generation/domain/generation_request.dart';
import '../../projects/application/projects_providers.dart';
import '../../projects/domain/project.dart';
import 'project_draft.dart';

/// Drives the creation wizard. Media is imported straight into the future
/// project's folder; if the wizard is closed without saving, the folder is
/// removed when this controller is disposed.
///
/// Async actions return an [AppFailure] for the UI to show, or null.
class ProjectDraftController extends Notifier<ProjectDraft> {
  var _saved = false;

  MediaPicker get _picker => ref.read(mediaPickerProvider);
  MediaImporter get _importer => ref.read(mediaImporterProvider);

  @override
  ProjectDraft build() {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final storage = ref.read(appStorageProvider);
    ref.onDispose(() {
      if (!_saved) _deleteQuietly(storage.projectDirectory(id));
    });
    return ProjectDraft(
      projectId: id,
      createdAt: now,
      title: 'Проект ${formatShortDateTime(now)}',
    );
  }

  Future<AppFailure?> pickSourceVideo() {
    return _import(const SourceVideoSlot(), () async {
      final picked = await _picker.pickVideo();
      if (picked == null) return;
      final asset = await _importer.importVideo(
        picked,
        projectId: state.projectId,
        limits: VideoLimits.source,
      );
      if (!ref.mounted) return;
      final old = state.sourceVideo;
      state = state.copyWith(sourceVideo: asset);
      if (old != null) await _importer.delete(old);
    });
  }

  void removeSourceVideo() {
    final old = state.sourceVideo;
    if (old == null || state.isBusy) return;
    state = state.copyWith(clearSourceVideo: true);
    _importer.delete(old);
  }

  Future<AppFailure?> addStyleReference() {
    if (!state.canAddStyleReference) return Future.value();
    return _import(const StyleReferenceSlot(), () async {
      final picked = await _picker.pickImageOrVideo();
      if (picked == null) return;
      final asset = picked.looksLikeVideo
          ? await _importer.importVideo(
              picked,
              projectId: state.projectId,
              limits: VideoLimits.reference,
            )
          : await _importer.importImage(picked, projectId: state.projectId);
      if (!ref.mounted) return;
      state = state.copyWith(
        styleReferences: [...state.styleReferences, asset],
      );
    });
  }

  void removeStyleReference(String assetId) {
    final asset = state.styleReferences.where((a) => a.id == assetId);
    if (asset.isEmpty || state.isBusy) return;
    state = state.copyWith(
      styleReferences: [
        for (final a in state.styleReferences)
          if (a.id != assetId) a,
      ],
    );
    _importer.delete(asset.first);
  }

  /// Returns the new character's id, or null when the limit is reached.
  String? addCharacter() {
    if (!state.canAddCharacter) return null;
    final character = CharacterReference(
      id: const Uuid().v4(),
      label: 'Персонаж ${state.characters.length + 1}',
    );
    state = state.copyWith(characters: [...state.characters, character]);
    return character.id;
  }

  void updateCharacter(String id, {String? label, String? description}) {
    state = state.copyWith(
      characters: [
        for (final c in state.characters)
          c.id == id ? c.copyWith(label: label, description: description) : c,
      ],
    );
  }

  void removeCharacter(String id) {
    if (state.isBusy) return;
    final removed = state.characters.where((c) => c.id == id).toList();
    state = state.copyWith(
      characters: [
        for (final c in state.characters)
          if (c.id != id) c,
      ],
    );
    for (final c in removed) {
      c.photos.forEach(_importer.delete);
    }
  }

  Future<AppFailure?> addCharacterPhotos(String characterId) {
    final character = _character(characterId);
    if (character == null) return Future.value();
    final room =
        GenerationRequest.maxPhotosPerCharacter - character.photos.length;
    if (room <= 0) return Future.value();

    return _import(CharacterPhotoSlot(characterId), () async {
      final picked = await _picker.pickImages(limit: room);
      final imported = <MediaAsset>[];
      AppFailure? firstFailure;
      for (final file in picked) {
        try {
          imported.add(
            await _importer.importImage(file, projectId: state.projectId),
          );
        } on AppFailure catch (f) {
          // Keep the good photos, report the first bad one.
          firstFailure ??= f;
        }
      }
      if (!ref.mounted) return;
      final current = _character(characterId);
      if (current != null && imported.isNotEmpty) {
        updatePhotos(characterId, [...current.photos, ...imported]);
      }
      if (firstFailure != null) throw firstFailure;
    });
  }

  void removeCharacterPhoto(String characterId, String assetId) {
    final character = _character(characterId);
    if (character == null || state.isBusy) return;
    final photo = character.photos.where((p) => p.id == assetId);
    if (photo.isEmpty) return;
    updatePhotos(characterId, [
      for (final p in character.photos)
        if (p.id != assetId) p,
    ]);
    _importer.delete(photo.first);
  }

  @visibleForTesting
  void updatePhotos(String characterId, List<MediaAsset> photos) {
    state = state.copyWith(
      characters: [
        for (final c in state.characters)
          c.id == characterId ? c.copyWith(photos: photos) : c,
      ],
    );
  }

  void setPrompt(String prompt) => state = state.copyWith(prompt: prompt);

  void setSettings(GenerationSettings settings) =>
      state = state.copyWith(settings: settings);

  void setTitle(String title) => state = state.copyWith(title: title);

  void setConsent(bool value) => state = state.copyWith(consentGiven: value);

  /// Persists the project. After success the media folder is kept even when
  /// the wizard closes.
  Future<(Project?, AppFailure?)> save() async {
    if (!state.canSave) {
      final errors = state.validationErrors;
      return (
        null,
        errors.isNotEmpty
            ? errors.first
            : const ValidationFailure(
                'Подтвердите права и согласие.',
                field: 'consent',
              ),
      );
    }
    final project = state.toProject(DateTime.now());
    try {
      await ref.read(projectsRepositoryProvider).save(project);
      _saved = true;
      ref.invalidate(recentProjectsProvider);
      return (project, null);
    } on AppFailure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnexpectedFailure(cause: e));
    }
  }

  CharacterReference? _character(String id) {
    for (final c in state.characters) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<AppFailure?> _import(
    ImportSlot slot,
    Future<void> Function() body,
  ) async {
    if (state.isBusy) return null;
    state = state.copyWith(importing: slot);
    try {
      await body();
      return null;
    } on AppFailure catch (f) {
      return f;
    } catch (e) {
      return UnexpectedFailure(cause: e);
    } finally {
      if (ref.mounted) state = state.copyWith(clearImporting: true);
    }
  }

  static void _deleteQuietly(Directory dir) {
    dir.delete(recursive: true).catchError((Object _) => dir);
  }
}

final projectDraftProvider =
    NotifierProvider.autoDispose<ProjectDraftController, ProjectDraft>(
      ProjectDraftController.new,
    );
