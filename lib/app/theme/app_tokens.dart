import 'package:flutter/material.dart';

/// Design tokens: the single source of colors, spacing and radii.
///
/// Widgets should read colors from [Theme.of(context).colorScheme] where a
/// Material role fits, and fall back to these tokens only for brand-specific
/// accents (gradients, glows) that Material roles do not cover.
abstract final class AppColors {
  static const background = Color(0xFF0B0B10);
  static const surface = Color(0xFF14141B);
  static const surfaceHigh = Color(0xFF1C1C26);
  static const surfaceHighest = Color(0xFF262633);
  static const outline = Color(0xFF34344A);

  static const primary = Color(0xFF9B7BFF);
  static const secondary = Color(0xFFFF6FB5);
  static const onAccent = Color(0xFF0B0B10);

  static const textPrimary = Color(0xFFF4F3FA);
  static const textSecondary = Color(0xFFA9A7BD);

  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF4ADE80);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Horizontal page padding used by every screen.
  static const page = EdgeInsets.symmetric(horizontal: md);
}

abstract final class AppRadii {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(24);

  static const card = BorderRadius.all(md);
  static const sheet = BorderRadius.vertical(top: lg);
}
