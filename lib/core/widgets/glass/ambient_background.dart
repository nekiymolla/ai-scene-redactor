import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Dark canvas with slowly drifting colour blobs. Glass is only visible when
/// there is something to refract, so every screen sits on top of this.
///
/// Motion stops when the system asks to reduce it (iOS Reduce Motion /
/// Android "remove animations"), which tests also rely on.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BlobPainter(_controller),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  // Anchor (fraction of size), drift radius (fraction of width), blob radius.
  static const _blobs = [
    (Offset(0.15, 0.12), 0.10, 0.75),
    (Offset(0.95, 0.38), 0.12, 0.70),
    (Offset(0.25, 0.85), 0.14, 0.80),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);

    final t = animation.value * 2 * math.pi;
    for (var i = 0; i < _blobs.length; i++) {
      final (anchor, drift, radius) = _blobs[i];
      final phase = t + i * 2.1;
      final center = Offset(
        size.width * anchor.dx + math.cos(phase) * drift * size.width,
        size.height * anchor.dy + math.sin(phase * 0.8) * drift * size.width,
      );
      final r = radius * size.width;
      final color = AppGlass.blobColors[i % AppGlass.blobColors.length];
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => false;
}
