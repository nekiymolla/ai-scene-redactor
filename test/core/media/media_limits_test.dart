import 'package:ai_scene_changer/core/media/media_limits.dart';
import 'package:ai_scene_changer/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoLimits.source', () {
    const limits = VideoLimits.source;
    const ok = 10 * 1024 * 1024;

    test('accepts 3–15 s', () {
      expect(
        limits.check(duration: const Duration(seconds: 3), sizeBytes: ok),
        isNull,
      );
      expect(
        limits.check(duration: const Duration(seconds: 15), sizeBytes: ok),
        isNull,
      );
    });

    test('tolerates rounding just above the maximum', () {
      expect(
        limits.check(
          duration: const Duration(milliseconds: 15400),
          sizeBytes: ok,
        ),
        isNull,
      );
    });

    test('rejects too short, too long and too big', () {
      expect(
        limits
            .check(duration: const Duration(seconds: 2), sizeBytes: ok)
            ?.message,
        contains('короткое'),
      );
      expect(
        limits
            .check(duration: const Duration(seconds: 16), sizeBytes: ok)
            ?.message,
        contains('длиннее 15'),
      );
      expect(
        limits
            .check(
              duration: const Duration(seconds: 5),
              sizeBytes: 201 * 1024 * 1024,
            )
            ?.message,
        contains('200 МБ'),
      );
    });
  });

  test('ImageLimits rejects images smaller than 300 px on any side', () {
    expect(ImageLimits.check(width: 300, height: 300), isNull);
    expect(ImageLimits.check(width: 299, height: 1000), isNotNull);
  });

  test('formatters', () {
    expect(formatDuration(const Duration(milliseconds: 7400)), '0:07');
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
    expect(formatBytes(5 * 1024 * 1024 + 400 * 1024), '5,4 МБ');
    expect(formatShortDateTime(DateTime(2026, 10, 4, 9, 5)), '04.10 09:05');
  });
}
