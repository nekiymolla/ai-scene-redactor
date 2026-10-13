import 'package:ai_scene_changer/core/errors/app_failure.dart';
import 'package:ai_scene_changer/core/storage/app_storage.dart';
import 'package:ai_scene_changer/features/project_creation/application/project_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late TestEnv env;
  late ProviderContainer container;

  ProjectDraftController controller() =>
      container.read(projectDraftProvider.notifier);

  setUp(() {
    env = TestEnv();
    container = env.container();
    // Keep the autoDispose draft alive for the whole test.
    container.listen(projectDraftProvider, (_, _) {});
  });

  tearDown(() => env.dispose());

  test('starts empty with a default title and cannot continue', () {
    final draft = container.read(projectDraftProvider);
    expect(draft.title, startsWith('Проект '));
    expect(draft.mediaStepDone, isFalse);
    expect(draft.canSave, isFalse);
  });

  test('picking a source video completes the media step', () async {
    env.picker.videos.add(picked('clip.mp4'));
    expect(await controller().pickSourceVideo(), isNull);

    final draft = container.read(projectDraftProvider);
    expect(draft.sourceVideo, isNotNull);
    expect(draft.mediaStepDone, isTrue);
    expect(draft.isBusy, isFalse);
  });

  test('cancelled picker changes nothing', () async {
    expect(await controller().pickSourceVideo(), isNull);
    expect(container.read(projectDraftProvider).sourceVideo, isNull);
  });

  test('replacing the video deletes the old file', () async {
    env.picker.videos
      ..add(picked('a.mp4'))
      ..add(picked('b.mp4'));
    await controller().pickSourceVideo();
    final first = container.read(projectDraftProvider).sourceVideo!.id;
    await controller().pickSourceVideo();

    expect(container.read(projectDraftProvider).sourceVideo!.id, isNot(first));
    expect(env.importer.deleted, [first]);
  });

  test('import failures are returned, not thrown', () async {
    env.picker.videos.add(picked('bad.mp4'));
    final failure = await controller().pickSourceVideo();
    expect(failure, isA<MediaFailure>());
    expect(container.read(projectDraftProvider).isBusy, isFalse);
  });

  test('character photos: limit, partial failures, removal', () async {
    final id = controller().addCharacter()!;
    env.picker.images.add([
      picked('a.jpg'),
      picked('bad.jpg'),
      picked('b.jpg'),
    ]);

    final failure = await controller().addCharacterPhotos(id);

    expect(env.picker.lastImageLimit, 4);
    expect(failure, isA<MediaFailure>());
    var character = container.read(projectDraftProvider).characters.single;
    expect(character.photos, hasLength(2));

    env.picker.images.add([picked('c.jpg')]);
    await controller().addCharacterPhotos(id);
    expect(env.picker.lastImageLimit, 2);

    controller().removeCharacterPhoto(id, character.photos.first.id);
    character = container.read(projectDraftProvider).characters.single;
    expect(character.photos, hasLength(2));
  });

  test('characters step needs a name and a photo for everyone', () async {
    final id = controller().addCharacter()!;
    expect(container.read(projectDraftProvider).charactersStepDone, isFalse);

    env.picker.images.add([picked('a.jpg')]);
    await controller().addCharacterPhotos(id);
    expect(container.read(projectDraftProvider).charactersStepDone, isTrue);

    controller().updateCharacter(id, label: '  ');
    expect(container.read(projectDraftProvider).charactersStepDone, isFalse);
  });

  test('no more than four characters', () {
    for (var i = 0; i < 4; i++) {
      expect(controller().addCharacter(), isNotNull);
    }
    expect(controller().addCharacter(), isNull);
  });

  test('save requires consent, then persists the project', () async {
    env.picker.videos.add(picked('clip.mp4'));
    await controller().pickSourceVideo();
    controller().setPrompt('  Осенний лес  ');

    var (project, failure) = await controller().save();
    expect(project, isNull);
    expect(failure, isA<ValidationFailure>());

    controller().setConsent(true);
    (project, failure) = await controller().save();
    expect(failure, isNull);
    expect(project!.prompt, 'Осенний лес');
    expect((await env.repository.byId(project.id))?.title, project.title);
  });

  test('closing the wizard without saving removes draft media', () async {
    final storage = container.read(appStorageProvider);
    final draftId = container.read(projectDraftProvider).projectId;
    final dir = storage.projectDirectory(draftId)..createSync(recursive: true);

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(dir.existsSync(), isFalse);
  });

  test('saved projects keep their media after the wizard closes', () async {
    final storage = container.read(appStorageProvider);
    env.picker.videos.add(picked('clip.mp4'));
    await controller().pickSourceVideo();
    controller()
      ..setPrompt('Лес')
      ..setConsent(true);
    final (project, _) = await controller().save();
    final dir = storage.projectDirectory(project!.id)
      ..createSync(recursive: true);

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(dir.existsSync(), isTrue);
  });
}
