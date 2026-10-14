import 'dart:collection';
import 'dart:io';

import 'package:ai_scene_changer/app/app.dart';
import 'package:ai_scene_changer/core/errors/app_failure.dart';
import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/core/media/media_importer.dart';
import 'package:ai_scene_changer/core/media/media_limits.dart';
import 'package:ai_scene_changer/core/media/media_picker.dart';
import 'package:ai_scene_changer/core/storage/app_storage.dart';
import 'package:ai_scene_changer/features/generation/application/generation_providers.dart';
import 'package:ai_scene_changer/features/generation/data/mock_generation_gateway.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_gateway.dart';
import 'package:ai_scene_changer/features/projects/application/projects_providers.dart';
import 'package:ai_scene_changer/features/projects/data/projects_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns queued results in order; returns "cancelled" when empty.
class FakeMediaPicker implements MediaPicker {
  final videos = Queue<PickedFile?>();
  final images = Queue<List<PickedFile>>();
  final media = Queue<PickedFile?>();
  int? lastImageLimit;

  @override
  Future<PickedFile?> pickVideo() async =>
      videos.isEmpty ? null : videos.removeFirst();

  @override
  Future<List<PickedFile>> pickImages({required int limit}) async {
    lastImageLimit = limit;
    return images.isEmpty ? const [] : images.removeFirst();
  }

  @override
  Future<PickedFile?> pickImageOrVideo() async =>
      media.isEmpty ? null : media.removeFirst();
}

/// Builds assets without touching the file system. Files whose name starts
/// with `bad` fail validation.
class FakeMediaImporter implements MediaImporter {
  final deleted = <String>[];
  var _counter = 0;

  @override
  Future<MediaAsset> importVideo(
    PickedFile file, {
    required String projectId,
    required VideoLimits limits,
  }) async {
    if (file.name.startsWith('bad')) {
      throw const MediaFailure('Видео слишком короткое');
    }
    final id = 'video${_counter++}';
    return MediaAsset(
      id: id,
      kind: MediaKind.video,
      relativePath: 'projects/$projectId/media/$id.mp4',
      duration: const Duration(seconds: 7),
      width: 1080,
      height: 1920,
      sizeBytes: 5 * 1024 * 1024,
    );
  }

  @override
  Future<MediaAsset> importImage(
    PickedFile file, {
    required String projectId,
  }) async {
    if (file.name.startsWith('bad')) {
      throw const MediaFailure('Фото слишком маленькое');
    }
    final id = 'image${_counter++}';
    return MediaAsset(
      id: id,
      kind: MediaKind.image,
      relativePath: 'projects/$projectId/media/$id.jpg',
      width: 1000,
      height: 1000,
    );
  }

  @override
  Future<void> delete(MediaAsset asset) async => deleted.add(asset.id);
}

PickedFile picked(String name) => PickedFile(path: '/tmp/$name', name: name);

/// Overrides every device dependency.
class TestEnv {
  TestEnv()
    : storageRoot = Directory.systemTemp.createTempSync('scene_test_'),
      picker = FakeMediaPicker(),
      importer = FakeMediaImporter(),
      repository = InMemoryProjectsRepository() {
    storage = AppStorage(storageRoot);
    gateway = MockGenerationGateway(
      storage,
      () => scenario,
      timeline: fastTimeline,
      store: MemoryMockJobStore(),
    );
  }

  /// 1 s upload, 1 s queue, 4 s processing.
  static const fastTimeline = MockTimeline(
    upload: Duration(seconds: 1),
    queue: Duration(seconds: 1),
    processing: Duration(seconds: 4),
  );
  static const pollInterval = Duration(milliseconds: 250);

  final Directory storageRoot;
  late final AppStorage storage;
  final FakeMediaPicker picker;
  final FakeMediaImporter importer;
  final ProjectsRepository repository;
  late final MockGenerationGateway gateway;
  var scenario = MockScenario.success;

  /// When true the mock reads the scenario from Settings like the real app,
  /// instead of from [scenario].
  var useSettingsScenario = false;

  /// Replaces [gateway] entirely, e.g. with a flaky wrapper.
  GenerationGateway? customGateway;

  List<Override> get overrides => [
    appStorageProvider.overrideWithValue(storage),
    mediaPickerProvider.overrideWithValue(picker),
    mediaImporterProvider.overrideWithValue(importer),
    projectsRepositoryProvider.overrideWithValue(repository),
    if (useSettingsScenario)
      generationGatewayProvider.overrideWith(
        (ref) => MockGenerationGateway(
          storage,
          () => ref.read(mockScenarioProvider),
          timeline: fastTimeline,
          store: MemoryMockJobStore(),
        ),
      )
    else
      generationGatewayProvider.overrideWithValue(customGateway ?? gateway),
    pollIntervalProvider.overrideWithValue(pollInterval),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    return c;
  }

  Widget app() => ProviderScope(overrides: overrides, child: const App());

  void dispose() {
    if (storageRoot.existsSync()) storageRoot.deleteSync(recursive: true);
  }
}

/// The ambient background animates forever unless the system asks to reduce
/// motion; widget tests run in that mode so pumpAndSettle can settle.
void reduceMotionInTests() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// iPhone-sized logical screen (390×844) instead of the default 800×600.
void usePhoneScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls the main list until [finder] is built and visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Advances fake time in small steps so timers and frames both run.
Future<void> advance(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 250);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
  await tester.pumpAndSettle();
}
