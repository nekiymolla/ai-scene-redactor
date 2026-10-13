// Runs DeviceMediaImporter against real platform plugins (video_player,
// fc_native_video_thumbnail, image decoding) on a simulator or device.
//
// Sample files are not committed (rights + size). Provide your own:
//   flutter test integration_test -d <device> \
//     --dart-define=SAMPLE_VIDEO=/abs/path/clip.mov \
//     --dart-define=SAMPLE_IMAGE=/abs/path/photo.png
// Absolute host paths work on the iOS simulator only.
import 'dart:io';

import 'package:ai_scene_changer/core/errors/app_failure.dart';
import 'package:ai_scene_changer/core/media/media_importer.dart';
import 'package:ai_scene_changer/core/media/media_limits.dart';
import 'package:ai_scene_changer/core/media/media_picker.dart';
import 'package:ai_scene_changer/core/storage/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _video = String.fromEnvironment('SAMPLE_VIDEO');
const _image = String.fromEnvironment('SAMPLE_IMAGE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;
  late DeviceMediaImporter importer;

  setUp(() async {
    final tmp = await getTemporaryDirectory();
    final root = Directory('${tmp.path}/import_test')
      ..createSync(recursive: true);
    storage = AppStorage(root);
    importer = DeviceMediaImporter(storage);
  });

  tearDown(() => storage.root.deleteSync(recursive: true));

  testWidgets('imports a real video with metadata and thumbnail', (_) async {
    final asset = await importer.importVideo(
      const PickedFile(path: _video, name: 'clip.mov'),
      projectId: 'p1',
      limits: VideoLimits.reference,
    );

    expect(asset.duration, isNotNull);
    expect(asset.duration!.inMilliseconds, greaterThan(1000));
    expect(asset.width, greaterThan(0));
    expect(asset.height, greaterThan(0));
    expect(storage.file(asset.relativePath).existsSync(), isTrue);
    expect(asset.thumbnailRelativePath, isNotNull);
    expect(
      storage.file(asset.thumbnailRelativePath!).lengthSync(),
      greaterThan(0),
    );

    // ignore: avoid_print
    print(
      'video: ${asset.duration} ${asset.width}x${asset.height} '
      '${asset.sizeBytes} bytes',
    );

    await importer.delete(asset);
    expect(storage.file(asset.relativePath).existsSync(), isFalse);
  }, skip: _video.isEmpty);

  testWidgets('enforces source limits on a real video', (_) async {
    const tight = VideoLimits(
      minDuration: Duration(seconds: 30),
      maxDuration: Duration(seconds: 60),
      maxBytes: 1 << 30,
    );
    await expectLater(
      importer.importVideo(
        const PickedFile(path: _video, name: 'clip.mov'),
        projectId: 'p1',
        limits: tight,
      ),
      throwsA(isA<MediaFailure>()),
    );
    // Nothing is copied for a rejected file.
    expect(storage.projectDirectory('p1').existsSync(), isFalse);
  }, skip: _video.isEmpty);

  testWidgets('imports a real image and reads its size', (_) async {
    final asset = await importer.importImage(
      const PickedFile(path: _image, name: 'photo.png'),
      projectId: 'p1',
    );
    // ignore: avoid_print
    print('image: ${asset.width}x${asset.height}');
    expect(asset.width, greaterThanOrEqualTo(ImageLimits.minSide));
    expect(storage.file(asset.relativePath).existsSync(), isTrue);
  }, skip: _image.isEmpty);

  testWidgets('rejects an unreadable video', (_) async {
    final bogus = File('${storage.root.path}/bogus.mp4')
      ..writeAsStringSync('not a video');
    await expectLater(
      importer.importVideo(
        PickedFile(path: bogus.path, name: 'bogus.mp4'),
        projectId: 'p1',
        limits: VideoLimits.source,
      ),
      throwsA(isA<MediaFailure>()),
    );
  });
}
