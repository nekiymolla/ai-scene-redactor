import 'package:ai_scene_changer/app/app.dart';
import 'package:ai_scene_changer/features/generation/domain/generation_job.dart';
import 'package:ai_scene_changer/features/generation/domain/media_asset.dart';
import 'package:ai_scene_changer/features/projects/application/projects_providers.dart';
import 'package:ai_scene_changer/features/projects/data/projects_repository.dart';
import 'package:ai_scene_changer/features/projects/domain/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the empty state when there are no projects', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет проектов'), findsOneWidget);
    expect(find.text('Новое видео'), findsOneWidget);
  });

  testWidgets('lists saved projects', (tester) async {
    final repo = InMemoryProjectsRepository();
    final now = DateTime(2026, 10, 14);
    await repo.save(
      Project(
        id: '1',
        title: 'Burning Bridges в лесу',
        createdAt: now,
        updatedAt: now,
        sourceVideo: const MediaAsset(
          id: 'v',
          kind: MediaKind.video,
          localPath: '/v.mp4',
        ),
        lastJobStatus: GenerationStatus.succeeded,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectsRepositoryProvider.overrideWithValue(repo)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Burning Bridges в лесу'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('Пока нет проектов'), findsNothing);
  });

  testWidgets('navigates to creation and settings', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Новое видео'));
    await tester.pumpAndSettle();
    expect(find.text('Новый проект'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.textContaining('Демо-режим'), findsOneWidget);
  });
}
