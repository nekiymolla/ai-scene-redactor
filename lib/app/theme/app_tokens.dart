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

/// Liquid-glass material parameters (iOS 26 inspired). Tuned for the dark
/// ambient background; glass needs colorful content behind it to read.
abstract final class AppGlass {
  static const blurSigma = 24.0;

  /// Backdrop saturation boost; real glass makes what is behind it richer.
  static const saturation = 1.5;

  static const fillTop = Color(0x29FFFFFF);
  static const fillBottom = Color(0x0DFFFFFF);
  static const strokeTop = Color(0x80FFFFFF);
  static const strokeBottom = Color(0x14FFFFFF);
  static const strokeWidth = 1.0;
  static const divider = Color(0x1FFFFFFF);

  /// Soft shadow that lifts floating glass off the content.
  static const shadow = BoxShadow(
    color: Color(0x59000000),
    blurRadius: 30,
    offset: Offset(0, 12),
  );

  /// Ambient background blobs.
  static const blobColors = [
    Color(0xFF6D4BFF),
    Color(0xFFFF4FA3),
    Color(0xFF2E8BFF),
  ];
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
  static const sm = Radius.circular(12);
  static const md = Radius.circular(22);
  static const lg = Radius.circular(32);

  static const card = BorderRadius.all(md);
  static const hero = BorderRadius.all(lg);
  static const sheet = BorderRadius.vertical(top: lg);
}
