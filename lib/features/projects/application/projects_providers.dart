import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_storage.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => FileProjectsRepository(ref.watch(appStorageProvider)),
);

final recentProjectsProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectsRepositoryProvider).recent(),
);

final projectProvider = FutureProvider.autoDispose.family<Project?, String>(
  (ref, id) => ref.watch(projectsRepositoryProvider).byId(id),
);

/// Deletes a project and refreshes every list that may show it.
final deleteProjectProvider = Provider<Future<void> Function(String id)>((ref) {
  return (id) async {
    await ref.read(projectsRepositoryProvider).delete(id);
    ref
      ..invalidate(recentProjectsProvider)
      ..invalidate(projectProvider(id));
  };
});
