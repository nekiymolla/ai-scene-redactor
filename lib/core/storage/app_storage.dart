import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-owned file storage rooted in the documents directory.
///
/// Everything persisted (projects, copied media) lives under [root] and is
/// referenced by paths relative to it.
class AppStorage {
  AppStorage(this.root);

  final Directory root;

  static const _projectsDir = 'projects';

  File file(String relativePath) => File('${root.path}/$relativePath');

  Directory get projectsDirectory => Directory('${root.path}/$_projectsDir');

  /// Relative path of a project's folder.
  String projectPath(String projectId) => '$_projectsDir/$projectId';

  Directory projectDirectory(String projectId) =>
      Directory('${root.path}/${projectPath(projectId)}');
}

/// Overridden in `main()` once the documents directory is known.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError('appStorageProvider must be overridden'),
);
