import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../media/media_asset.dart';
import '../../storage/app_storage.dart';
import '../../utils/formatters.dart';
import '../glass/glass_surface.dart';

/// Square preview of an image, or of a video's thumbnail with a duration
/// badge. Shows a neutral placeholder if the file cannot be decoded.
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({
    super.key,
    required this.asset,
    this.size = 88,
    this.onRemove,
    this.removeLabel = 'Удалить',
  });

  final MediaAsset asset;
  final double size;
  final VoidCallback? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(appStorageProvider);
    final imagePath = asset.isVideo
        ? asset.thumbnailRelativePath
        : asset.relativePath;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRSuperellipse(
            borderRadius: AppRadii.thumb,
            child: imagePath == null
                ? _placeholder()
                : Image.file(
                    storage.file(imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: (size * 3).round(),
                    errorBuilder: (_, _, _) => _placeholder(),
                  ),
          ),
          if (asset.isVideo)
            Positioned(
              left: 6,
              bottom: 6,
              child: _Badge(
                icon: Icons.play_arrow_rounded,
                text: asset.duration == null
                    ? null
                    : formatDuration(asset.duration!),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: removeLabel,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onRemove,
                  child: const _Badge(icon: Icons.close_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => ColoredBox(
    color: AppColors.surfaceHigh,
    child: Icon(
      asset.isVideo ? Icons.movie_outlined : Icons.image_outlined,
      color: AppColors.textSecondary,
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, this.text});

  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0x99000000),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: text == null ? 3 : 6,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            if (text != null) ...[
              const SizedBox(width: 2),
              Text(
                text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glass tile that opens a picker. Shows a spinner while [busy].
class AddMediaTile extends StatelessWidget {
  const AddMediaTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.size = 88,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: GlassSurface(
            shape: const RoundedSuperellipseBorder(
              borderRadius: AppRadii.thumb,
            ),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: busy
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: AppColors.textPrimary),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
