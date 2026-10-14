import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/features/generation/data/mock_generation_gateway.dart';
import 'package:ai_scene_changer/features/projects/domain/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  reduceMotionInTests();

  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  Future<void> openProject(WidgetTester tester) async {
    await env.repository.save(
      Project(
        id: 'p1',
        title: 'Танец в лесу',
        createdAt: DateTime(2026, 10, 14),
        updatedAt: DateTime(2026, 10, 14),
        sourceVideo: const MediaAsset(
          id: 'v',
          kind: MediaKind.video,
          relativePath: 'projects/p1/media/v.mp4',
          duration: Duration(seconds: 7),
        ),
        prompt: 'Осенний лес',
      ),
    );
    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Танец в лесу'));
    await tester.pumpAndSettle();
  }

  testWidgets('failure shows the reason and can be retried', (tester) async {
    env.scenario = MockScenario.failure;
    await openProject(tester);

    await tester.tap(find.text('Создать видео'));
    await tester.pumpAndSettle();
    expect(find.text('Создаём видео'), findsOneWidget);
    expect(find.text('Отменить'), findsOneWidget);

    await advance(tester, const Duration(seconds: 6));
    expect(find.text('Не получилось'), findsOneWidget);
    expect(find.textContaining('имитация ошибки'), findsOneWidget);

    env.scenario = MockScenario.success;
    await tester.tap(find.text('Попробовать снова'));
    await advance(tester, const Duration(seconds: 7));
    expect(find.text('Тестовый результат, не AI'), findsOneWidget);
  });

  testWidgets('cancel asks for confirmation and stops the job', (tester) async {
    await openProject(tester);
    await tester.tap(find.text('Создать видео'));
    await advance(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить генерацию'));
    await tester.pumpAndSettle();

    expect(find.text('Генерация отменена'), findsOneWidget);
    expect(find.text('Попробовать снова'), findsOneWidget);
  });

  testWidgets('leaving processing keeps the job; the project shows progress', (
    tester,
  ) async {
    await openProject(tester);
    await tester.tap(find.text('Создать видео'));
    await advance(tester, const Duration(seconds: 3));

    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Идёт обработка'), findsOneWidget);
    expect(find.text('Смотреть прогресс'), findsOneWidget);

    await advance(tester, const Duration(seconds: 5));
    expect(find.text('Видео готово'), findsOneWidget);
  });

  testWidgets('settings toggle makes the next demo job fail', (tester) async {
    env.useSettingsScenario = true;
    await openProject(tester);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Следующая генерация с ошибкой'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Танец в лесу'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать видео'));
    await advance(tester, const Duration(seconds: 6));
    expect(find.text('Не получилось'), findsOneWidget);
  });
}
