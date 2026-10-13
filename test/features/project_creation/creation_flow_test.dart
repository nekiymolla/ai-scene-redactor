import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  reduceMotionInTests();

  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('creates, saves and deletes a project', (tester) async {
    env.picker.videos.add(picked('clip.mp4'));
    env.picker.images.add([picked('face.jpg')]);

    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();

    // Step 1: source video. "Далее" does nothing until a video is picked.
    await tapText(tester, 'Новое видео');
    expect(find.text('Шаг 1 из 4'), findsOneWidget);
    await tapText(tester, 'Далее');
    expect(find.text('Шаг 1 из 4'), findsOneWidget);

    await tapText(tester, 'Выбрать видео из галереи');
    expect(find.textContaining('1080×1920'), findsOneWidget);
    await tapText(tester, 'Далее');

    // Step 2: one character with one photo.
    expect(find.text('Шаг 2 из 4'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
    await tapText(tester, 'Добавить персонажа');
    await tapText(tester, 'Фото');
    expect(find.textContaining('Фото: 1 из 4'), findsOneWidget);
    await tapText(tester, 'Далее');

    // Step 3: prompt via a suggestion chip.
    expect(find.text('Шаг 3 из 4'), findsOneWidget);
    await tapText(tester, 'Перенеси действие в осенний лес');
    await tapText(tester, 'Далее');

    // Step 4: saving requires consent.
    expect(find.text('Шаг 4 из 4'), findsOneWidget);
    await tapText(tester, 'Сохранить проект');
    expect(find.text('Шаг 4 из 4'), findsOneWidget);

    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    await tapText(tester, 'Сохранить проект');

    // Project details.
    expect(find.text('Генерация пока недоступна'), findsOneWidget);
    await scrollTo(tester, find.text('Перенеси действие в осенний лес'));
    expect(find.text('Перенеси действие в осенний лес'), findsOneWidget);
    expect(await env.repository.recent(), hasLength(1));

    await tester.tap(find.byTooltip('Удалить проект'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет проектов'), findsOneWidget);
    expect(await env.repository.recent(), isEmpty);
  });

  testWidgets('shows import errors to the user', (tester) async {
    env.picker.videos.add(picked('bad.mp4'));
    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();

    await tapText(tester, 'Новое видео');
    await tapText(tester, 'Выбрать видео из галереи');

    expect(find.text('Видео слишком короткое'), findsOneWidget);
    expect(find.text('Выбрать видео из галереи'), findsOneWidget);
  });
}
