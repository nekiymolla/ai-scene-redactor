import 'package:ai_scene_changer/core/media/media_asset.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/projects/domain/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  reduceMotionInTests();

  late TestEnv env;
  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  testWidgets('shows the empty state when there are no projects', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();

    expect(find.text('Пока нет проектов'), findsOneWidget);
    expect(find.text('Новое видео'), findsOneWidget);
    expect(find.byTooltip('Назад'), findsNothing);
  });

  testWidgets('lists saved projects and opens one', (tester) async {
    final now = DateTime(2026, 10, 14);
    await env.repository.save(
      Project(
        id: '1',
        title: 'Burning Bridges в лесу',
        createdAt: now,
        updatedAt: now,
        sourceVideo: const MediaAsset(
          id: 'v',
          kind: MediaKind.video,
          relativePath: 'projects/1/media/v.mp4',
        ),
        prompt: 'Осенний лес',
        lastJobStatus: GenerationStatus.succeeded,
      ),
    );

    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();

    expect(find.text('Burning Bridges в лесу'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('Пока нет проектов'), findsNothing);

    await tester.tap(find.text('Burning Bridges в лесу'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Назад'), findsOneWidget);
    await scrollTo(tester, find.text('Осенний лес'));
    expect(find.text('Осенний лес'), findsOneWidget);
  });

  testWidgets('opens settings and the privacy sheet', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(env.app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.textContaining('Демо-режим'), findsOneWidget);

    await tester.tap(find.text('Конфиденциальность'));
    await tester.pumpAndSettle();
    expect(find.textContaining('без регистрации'), findsOneWidget);
  });
}
