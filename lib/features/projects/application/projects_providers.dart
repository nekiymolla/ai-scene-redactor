import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/projects_repository.dart';
import '../domain/project.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => InMemoryProjectsRepository(),
);

final recentProjectsProvider = FutureProvider<List<Project>>(
  (ref) => ref.watch(projectsRepositoryProvider).recent(),
);
