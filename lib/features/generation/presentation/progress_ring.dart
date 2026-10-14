import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/glass/glass_surface.dart';

/// Glass disc with a gradient progress arc. [progress] null = indeterminate:
/// a rotating arc, or a static one when the system asks to reduce motion.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 220,
  });

  final double? progress;
  final Widget child;
  final double size;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spin =
        widget.progress == null && !MediaQuery.disableAnimationsOf(context);
    if (spin && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!spin && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.progress == null
          ? 'Идёт обработка'
          : 'Готово на ${(widget.progress! * 100).round()} процентов',
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GlassSurface(
              shape: const CircleBorder(),
              child: SizedBox.square(dimension: widget.size),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: widget.progress ?? 0.25),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => CustomPaint(
                  size: Size.square(widget.size),
                  painter: _ArcPainter(
                    sweep: value,
                    rotation: widget.progress == null ? _spin.value : 0,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.sweep, required this.rotation});

  final double sweep;
  final double rotation;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2 + 6);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppGlass.divider,
    );
    if (sweep <= 0) return;
    final start = -math.pi / 2 + rotation * 2 * math.pi;
    canvas.drawArc(
      rect,
      start,
      2 * math.pi * sweep.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(start),
          colors: const [AppColors.primary, AppColors.secondary],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.sweep != sweep || old.rotation != rotation;
}
