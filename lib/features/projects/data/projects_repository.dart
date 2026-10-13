import '../domain/project.dart';

/// Device-local project history. A cloud-backed implementation can be added
/// behind the same interface once accounts exist.
abstract interface class ProjectsRepository {
  /// Most recently updated first.
  Future<List<Project>> recent({int limit = 20});

  Future<void> save(Project project);

  Future<void> delete(String projectId);
}

/// Keeps projects in memory for the current app session only.
///
/// Temporary: replaced by a file/SQLite-backed store in task P2-08, see
/// DEVELOPMENT_PLAN.md.
class InMemoryProjectsRepository implements ProjectsRepository {
  final _projects = <String, Project>{};

  @override
  Future<List<Project>> recent({int limit = 20}) async {
    final sorted = _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> save(Project project) async => _projects[project.id] = project;

  @override
  Future<void> delete(String projectId) async => _projects.remove(projectId);
}
