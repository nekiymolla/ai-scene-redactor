import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_request.dart';
import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:flutter_test/flutter_test.dart';

const _video = MediaAsset(
  id: 'v',
  kind: MediaKind.video,
  relativePath: '/v.mp4',
);
const _photo = MediaAsset(
  id: 'p',
  kind: MediaKind.image,
  relativePath: '/p.jpg',
);

CharacterReference _character(String id, {int photos = 1}) =>
    CharacterReference(
      id: id,
      label: 'Персонаж $id',
      photos: List.filled(photos, _photo),
    );

void main() {
  group('GenerationRequest.validate', () {
    test('accepts a prompt-only request', () {
      const request = GenerationRequest(
        sourceVideo: _video,
        prompt: 'Лес вместо ресторана',
      );
      expect(request.validate(), isEmpty);
    });

    test('accepts characters without a prompt', () {
      final request = GenerationRequest(
        sourceVideo: _video,
        prompt: '  ',
        characters: [_character('1')],
      );
      expect(request.validate(), isEmpty);
    });

    test('rejects an empty request', () {
      const request = GenerationRequest(sourceVideo: _video, prompt: ' ');
      expect(request.validate().map((f) => f.field), ['prompt']);
    });

    test('rejects a non-video source', () {
      const request = GenerationRequest(sourceVideo: _photo, prompt: 'x');
      expect(request.validate().map((f) => f.field), ['sourceVideo']);
    });

    test('rejects a too long prompt', () {
      final request = GenerationRequest(
        sourceVideo: _video,
        prompt: 'a' * (GenerationRequest.maxPromptLength + 1),
      );
      expect(request.validate().map((f) => f.field), ['prompt']);
    });

    test('rejects too many characters and characters without photos', () {
      final request = GenerationRequest(
        sourceVideo: _video,
        prompt: 'x',
        characters: [
          for (var i = 0; i < GenerationRequest.maxCharacters; i++)
            _character('$i'),
          _character('empty', photos: 0),
        ],
      );
      final fields = request.validate().map((f) => f.field).toList();
      expect(fields, ['characters', 'characters']);
    });
  });

  test('GenerationStatus.isTerminal', () {
    expect(GenerationStatus.values.where((s) => s.isTerminal), [
      GenerationStatus.succeeded,
      GenerationStatus.failed,
      GenerationStatus.cancelled,
    ]);
  });

  test('MediaAsset survives a JSON round trip', () {
    const asset = MediaAsset(
      id: 'a',
      kind: MediaKind.video,
      relativePath: '/a.mp4',
      sizeBytes: 10,
      duration: Duration(milliseconds: 4200),
      width: 1080,
      height: 1920,
    );
    final copy = MediaAsset.fromJson(asset.toJson());
    expect(copy.toJson(), asset.toJson());
  });
}
