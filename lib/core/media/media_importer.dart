import 'dart:io';
import 'dart:ui' as ui;

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import 'media_asset.dart';
import '../errors/app_failure.dart';
import '../storage/app_storage.dart';
import 'media_limits.dart';
import 'media_picker.dart';

/// Copies picked files into a project's folder, reads their metadata and
/// enforces [VideoLimits] / [ImageLimits]. Throws [AppFailure].
abstract interface class MediaImporter {
  Future<MediaAsset> importVideo(
    PickedFile file, {
    required String projectId,
    required VideoLimits limits,
  });

  Future<MediaAsset> importImage(PickedFile file, {required String projectId});

  /// Removes the asset's files. Missing files are ignored.
  Future<void> delete(MediaAsset asset);
}

class DeviceMediaImporter implements MediaImporter {
  DeviceMediaImporter(this._storage);

  final AppStorage _storage;
  final _uuid = const Uuid();

  @override
  Future<MediaAsset> importVideo(
    PickedFile file, {
    required String projectId,
    required VideoLimits limits,
  }) async {
    final source = File(file.path);
    final size = await _length(source);

    final (duration, width, height) = await _probeVideo(source);
    final failure = limits.check(duration: duration, sizeBytes: size);
    if (failure != null) throw failure;

    final id = _uuid.v4();
    final relative = _mediaPath(projectId, id, _extension(file.name, 'mp4'));
    await _copy(source, relative);

    final thumbRelative = _mediaPath(projectId, '${id}_thumb', 'jpg');
    final hasThumb = await _thumbnail(_storage.file(relative), thumbRelative);

    return MediaAsset(
      id: id,
      kind: MediaKind.video,
      relativePath: relative,
      thumbnailRelativePath: hasThumb ? thumbRelative : null,
      sizeBytes: size,
      duration: duration,
      width: width,
      height: height,
    );
  }

  @override
  Future<MediaAsset> importImage(
    PickedFile file, {
    required String projectId,
  }) async {
    final source = File(file.path);
    final size = await _length(source);
    final (width, height) = await _imageSize(source);
    final failure = ImageLimits.check(width: width, height: height);
    if (failure != null) throw failure;

    final id = _uuid.v4();
    final relative = _mediaPath(projectId, id, _extension(file.name, 'jpg'));
    await _copy(source, relative);
    return MediaAsset(
      id: id,
      kind: MediaKind.image,
      relativePath: relative,
      sizeBytes: size,
      width: width,
      height: height,
    );
  }

  @override
  Future<void> delete(MediaAsset asset) async {
    for (final path in [asset.relativePath, ?asset.thumbnailRelativePath]) {
      try {
        await _storage.file(path).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  String _mediaPath(String projectId, String name, String ext) =>
      '${_storage.projectPath(projectId)}/media/$name.$ext';

  static String _extension(String name, String fallback) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return fallback;
    return name.substring(dot + 1).toLowerCase();
  }

  static Future<int> _length(File file) async {
    try {
      return await file.length();
    } on FileSystemException catch (e) {
      throw MediaFailure('Не удалось прочитать файл.', cause: e);
    }
  }

  Future<void> _copy(File source, String relative) async {
    try {
      final dest = _storage.file(relative);
      await dest.parent.create(recursive: true);
      await source.copy(dest.path);
    } on FileSystemException catch (e) {
      throw StorageFailure(
        'Не удалось сохранить файл. Проверьте свободное место.',
        cause: e,
      );
    }
  }

  /// Uses the platform video player to read duration and dimensions; it
  /// supports exactly the codecs the device can play.
  static Future<(Duration, int?, int?)> _probeVideo(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final value = controller.value;
      final size = value.size;
      return (
        value.duration,
        size.isEmpty ? null : size.width.round(),
        size.isEmpty ? null : size.height.round(),
      );
    } catch (e) {
      throw MediaFailure(
        'Не удалось прочитать видео. Возможно, формат не поддерживается.',
        cause: e,
      );
    } finally {
      await controller.dispose();
    }
  }

  /// Reads image dimensions from the header without decoding pixels.
  static Future<(int, int)> _imageSize(File file) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return (descriptor.width, descriptor.height);
    } catch (e) {
      throw MediaFailure('Не удалось прочитать фото.', cause: e);
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Best effort: a missing thumbnail only degrades the UI.
  Future<bool> _thumbnail(File video, String relative) async {
    try {
      return await FcNativeVideoThumbnail().saveThumbnailToFile(
        srcFile: video.path,
        destFile: _storage.file(relative).path,
        width: 720,
        height: 720,
        format: 'jpeg',
        quality: 85,
      );
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
      return false;
    }
  }
}

final mediaImporterProvider = Provider<MediaImporter>(
  (ref) => DeviceMediaImporter(ref.watch(appStorageProvider)),
);
