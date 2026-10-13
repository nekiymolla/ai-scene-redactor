import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_tokens.dart';
import '../../media/media_asset.dart';
import '../../storage/app_storage.dart';
import '../../utils/formatters.dart';

/// Large video preview. Shows the thumbnail first and creates the platform
/// player only on tap, so lists and screens stay light until the user
/// actually wants to watch.
class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({super.key, required this.asset, this.maxHeight = 420});

  final MediaAsset asset;
  final double maxHeight;

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview> {
  VideoPlayerController? _controller;
  var _failed = false;
  var _loading = false;

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) _disposePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _disposePlayer() {
    _controller?.dispose();
    _controller = null;
    _failed = false;
    _loading = false;
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller != null) {
      controller.value.isPlaying ? controller.pause() : controller.play();
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    final storage = ref.read(appStorageProvider);
    final created = VideoPlayerController.file(
      storage.file(widget.asset.relativePath),
    );
    try {
      await created.initialize();
      await created.setLooping(true);
      if (!mounted) {
        await created.dispose();
        return;
      }
      created.addListener(_onTick);
      setState(() {
        _controller = created;
        _loading = false;
      });
      await created.play();
    } catch (_) {
      await created.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  double get _aspectRatio {
    final c = _controller;
    if (c != null && c.value.isInitialized && c.value.aspectRatio > 0) {
      return c.value.aspectRatio;
    }
    final w = widget.asset.width, h = widget.asset.height;
    if (w != null && h != null && w > 0 && h > 0) return w / h;
    return 9 / 16;
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(appStorageProvider);
    final thumb = widget.asset.thumbnailRelativePath;
    final controller = _controller;
    final playing = controller?.value.isPlaying ?? false;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: ClipRSuperellipse(
            borderRadius: AppRadii.card,
            child: Semantics(
              button: true,
              label: playing ? 'Пауза' : 'Воспроизвести видео',
              child: GestureDetector(
                onTap: _failed ? null : _toggle,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (controller != null)
                      VideoPlayer(controller)
                    else if (thumb != null)
                      Image.file(
                        storage.file(thumb),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: AppColors.surfaceHigh),
                      )
                    else
                      const ColoredBox(color: AppColors.surfaceHigh),
                    if (!playing)
                      Center(
                        child: _failed
                            ? const _Overlay(
                                icon: Icons.error_outline,
                                text: 'Не удалось воспроизвести видео',
                              )
                            : _loading
                            ? const CircularProgressIndicator()
                            : const _Overlay(icon: Icons.play_arrow_rounded),
                      ),
                    if (widget.asset.duration != null && !playing)
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: _Overlay(
                          text: formatDuration(widget.asset.duration!),
                          compact: true,
                        ),
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

class _Overlay extends StatelessWidget {
  const _Overlay({this.icon, this.text, this.compact = false});

  final IconData? icon;
  final String? text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0x80000000),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 14,
          vertical: compact ? 4 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 32),
            if (icon != null && text != null) const SizedBox(width: 6),
            if (text != null)
              Text(
                text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
