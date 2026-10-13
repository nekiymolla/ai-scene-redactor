import 'dart:io';

import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/core/storage/app_storage.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_request.dart';
import 'package:ai_scene_changer/features/projects/data/projects_repository.dart';
import 'package:ai_scene_changer/features/projects/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project(String id, DateTime updated) => Project(
  id: id,
  title: 'Проект $id',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: updated,
  sourceVideo: MediaAsset(
    id: 'v',
    kind: MediaKind.video,
    relativePath: 'projects/$id/media/v.mp4',
    thumbnailRelativePath: 'projects/$id/media/v_thumb.jpg',
    duration: const Duration(seconds: 7),
  ),
  characters: [
    CharacterReference(
      id: 'c1',
      label: 'Аня',
      description: 'девушка слева',
      photos: [
        MediaAsset(
          id: 'p1',
          kind: MediaKind.image,
          relativePath: 'projects/$id/media/p1.jpg',
        ),
      ],
    ),
  ],
  prompt: 'Осенний лес',
  settings: const GenerationSettings(
    resolution: OutputResolution.p720,
    keepOriginalAudio: false,
  ),
  lastJobStatus: GenerationStatus.failed,
);

void main() {
  late Directory root;
  late AppStorage storage;
  late FileProjectsRepository repo;

  setUp(() {
    root = Directory.systemTemp.createTempSync('projects_repo_');
    storage = AppStorage(root);
    repo = FileProjectsRepository(storage);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('Project survives a JSON round trip', () {
    final p = _project('a', DateTime(2026, 10, 14, 2, 10));
    final copy = Project.fromJson(p.toJson());
    expect(copy.toJson(), p.toJson());
    expect(copy.characters.single.photos.single.id, 'p1');
    expect(copy.settings.resolution, OutputResolution.p720);
  });

  test('returns an empty list before anything is saved', () async {
    expect(await repo.recent(), isEmpty);
  });

  test('saves, lists newest first and loads by id', () async {
    await repo.save(_project('old', DateTime(2026, 10, 1)));
    await repo.save(_project('new', DateTime(2026, 10, 2)));

    final recent = await repo.recent();
    expect(recent.map((p) => p.id), ['new', 'old']);
    expect((await repo.byId('old'))?.prompt, 'Осенний лес');
    expect(await repo.byId('missing'), isNull);
  });

  test('skips abandoned drafts and corrupt files', () async {
    await repo.save(_project('good', DateTime(2026, 10, 1)));
    // A draft folder with media but no project.json.
    Directory(
      '${storage.projectDirectory('draft').path}/media',
    ).createSync(recursive: true);
    // A corrupt project.
    File('${storage.projectDirectory('broken').path}/project.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');

    expect((await repo.recent()).map((p) => p.id), ['good']);
  });

  test('delete removes the whole project folder with media', () async {
    await repo.save(_project('a', DateTime(2026, 10, 1)));
    final media = storage.file('projects/a/media/v.mp4')
      ..createSync(recursive: true);

    await repo.delete('a');

    expect(media.existsSync(), isFalse);
    expect(storage.projectDirectory('a').existsSync(), isFalse);
    expect(await repo.recent(), isEmpty);
  });
}
