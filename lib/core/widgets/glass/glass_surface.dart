import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// A piece of liquid glass: blurred, saturated backdrop, a light gradient
/// fill and a specular rim brighter at the top edge.
///
/// This is the only place that knows how glass is drawn. If a refraction
/// shader is adopted later, it replaces the internals here without touching
/// screens.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const RoundedSuperellipseBorder(borderRadius: AppRadii.card),
    this.padding = EdgeInsets.zero,
    this.tint,
    this.floating = false,
  });

  /// Capsule, the iOS 26 shape for buttons and floating bars.
  const GlassSurface.capsule({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.floating = true,
  }) : shape = const StadiumBorder();

  final Widget child;
  final OutlinedBorder shape;
  final EdgeInsetsGeometry padding;

  /// Optional colour mixed into the glass, e.g. the accent for primary actions.
  final Color? tint;

  /// Floating chrome (bars, FABs) that hovers over other glass must sample
  /// the live backdrop and casts a shadow. In-content cards share one backdrop
  /// snapshot via [BackdropGroup], which is much cheaper in scrolling lists.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final filter = ui.ImageFilter.compose(
      outer: _saturation(AppGlass.saturation),
      inner: ui.ImageFilter.blur(
        sigmaX: AppGlass.blurSigma,
        sigmaY: AppGlass.blurSigma,
      ),
    );

    Widget glass = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: floating
          ? BackdropFilter(filter: filter, child: _content())
          : BackdropFilter.grouped(filter: filter, child: _content()),
    );

    if (floating) {
      glass = DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: const [AppGlass.shadow],
        ),
        child: glass,
      );
    }
    return glass;
  }

  Widget _content() {
    return CustomPaint(
      painter: _GlassPainter(shape: shape, tint: tint),
      child: Padding(padding: padding, child: child),
    );
  }

  static ColorFilter _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final inv = 1 - s;
    return ColorFilter.matrix([
      r * inv + s, g * inv, b * inv, 0, 0, //
      r * inv, g * inv + s, b * inv, 0, 0, //
      r * inv, g * inv, b * inv + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.shape, required this.tint});

  final OutlinedBorder shape;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);

    final top = tint == null
        ? AppGlass.fillTop
        : Color.alphaBlend(tint!.withValues(alpha: 0.75), AppGlass.fillTop);
    final bottom = tint == null
        ? AppGlass.fillBottom
        : Color.alphaBlend(
            AppColors.secondary.withValues(alpha: 0.55),
            AppGlass.fillBottom,
          );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ).createShader(rect),
    );

    // Specular rim: bright where light hits the top edge, fading downwards.
    final rim = shape.getInnerPath(rect.deflate(AppGlass.strokeWidth / 2));
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppGlass.strokeWidth
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppGlass.strokeTop,
            AppGlass.strokeBottom,
            Color(0x26FFFFFF),
          ],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.shape != shape || old.tint != tint;
}
