import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/app_storage.dart';
import '../domain/project.dart';

/// Device-local project history. A cloud-backed implementation can be added
/// behind the same interface once accounts exist. Throws [StorageFailure].
abstract interface class ProjectsRepository {
  /// Most recently updated first.
  Future<List<Project>> recent({int limit = 50});

  Future<Project?> byId(String projectId);

  Future<void> save(Project project);

  /// Deletes the project together with all of its media.
  Future<void> delete(String projectId);
}

/// One folder per project: `projects/<id>/project.json` plus `media/`.
///
/// A JSON file per project is enough for a local history of dozens of items
/// and keeps project data and media in one place (see docs/DECISIONS.md).
class FileProjectsRepository implements ProjectsRepository {
  FileProjectsRepository(this._storage);

  final AppStorage _storage;

  static const _fileName = 'project.json';

  File _metaFile(String id) =>
      File('${_storage.projectDirectory(id).path}/$_fileName');

  @override
  Future<List<Project>> recent({int limit = 50}) async {
    final dir = _storage.projectsDirectory;
    if (!await dir.exists()) return const [];
    final projects = <Project>[];
    try {
      await for (final entry in dir.list()) {
        if (entry is! Directory) continue;
        final project = await _read(File('${entry.path}/$_fileName'));
        if (project != null) projects.add(project);
      }
    } on FileSystemException catch (e) {
      throw StorageFailure('Не удалось загрузить проекты.', cause: e);
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects.take(limit).toList();
  }

  @override
  Future<Project?> byId(String projectId) => _read(_metaFile(projectId));

  @override
  Future<void> save(Project project) async {
    final file = _metaFile(project.id);
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(jsonEncode(project.toJson()), flush: true);
      // Rename is atomic, so a crash never leaves a half-written project.
      await tmp.rename(file.path);
    } on FileSystemException catch (e) {
      throw StorageFailure(
        'Не удалось сохранить проект. Проверьте свободное место.',
        cause: e,
      );
    }
  }

  @override
  Future<void> delete(String projectId) async {
    final dir = _storage.projectDirectory(projectId);
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      throw StorageFailure('Не удалось удалить проект.', cause: e);
    }
  }

  /// Returns null for missing or unreadable files: drafts abandoned before
  /// saving have media but no project.json, and one corrupt project must
  /// not hide the others.
  Future<Project?> _read(File file) async {
    try {
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return Project.fromJson((json as Map).cast());
    } catch (e) {
      debugPrint('Skipping unreadable project ${file.path}: $e');
      return null;
    }
  }
}

/// Keeps projects in memory. Used in tests.
class InMemoryProjectsRepository implements ProjectsRepository {
  final _projects = <String, Project>{};

  @override
  Future<List<Project>> recent({int limit = 50}) async {
    final sorted = _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<Project?> byId(String projectId) async => _projects[projectId];

  @override
  Future<void> save(Project project) async => _projects[project.id] = project;

  @override
  Future<void> delete(String projectId) async => _projects.remove(projectId);
}
