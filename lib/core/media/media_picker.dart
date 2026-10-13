import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_failure.dart';
import 'media_limits.dart';

/// A file chosen in the system picker. Lives in a temporary location until
/// imported by `MediaImporter`.
class PickedFile {
  const PickedFile({required this.path, required this.name});

  final String path;
  final String name;

  bool get looksLikeVideo {
    final ext = name.split('.').last.toLowerCase();
    return const {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'}.contains(ext);
  }
}

/// System media picker. Returns empty results when the user cancels and
/// throws [AppFailure] on errors.
abstract interface class MediaPicker {
  Future<PickedFile?> pickVideo();

  Future<List<PickedFile>> pickImages({required int limit});

  Future<PickedFile?> pickImageOrVideo();
}

/// Uses the system photo picker (PHPicker on iOS, Photo Picker on Android),
/// which needs no gallery permission as long as full metadata is not
/// requested.
class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxSide = ImageLimits.maxSide * 1.0;
  static const _quality = 90;

  @override
  Future<PickedFile?> pickVideo() => _guard(() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    return file == null ? null : PickedFile(path: file.path, name: file.name);
  });

  @override
  Future<List<PickedFile>> pickImages({required int limit}) => _guard(() async {
    if (limit <= 0) return const [];
    final files = limit == 1
        ? [
            ?await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: _maxSide,
              maxHeight: _maxSide,
              imageQuality: _quality,
              requestFullMetadata: false,
            ),
          ]
        : await _picker.pickMultiImage(
            maxWidth: _maxSide,
            maxHeight: _maxSide,
            imageQuality: _quality,
            limit: limit,
            requestFullMetadata: false,
          );
    return [
      for (final f in files.take(limit)) PickedFile(path: f.path, name: f.name),
    ];
  });

  @override
  Future<PickedFile?> pickImageOrVideo() => _guard(() async {
    final file = await _picker.pickMedia(
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      requestFullMetadata: false,
    );
    return file == null ? null : PickedFile(path: file.path, name: file.name);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw const PermissionFailure(
          'Нет доступа к фото. Разрешите доступ в настройках устройства.',
        );
      }
      throw MediaFailure('Не удалось открыть файл.', cause: e);
    }
  }
}

final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => ImagePickerMediaPicker(),
);
