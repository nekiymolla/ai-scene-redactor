import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tokens.dart';
import 'glass_surface.dart';

/// Squishes slightly while pressed, like iOS 26 glass controls.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  var _pressed = false;

  void _set(bool v) {
    if (widget.onPressed != null && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.5,
            duration: const Duration(milliseconds: 150),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Capsule glass button. [prominent] tints it with the accent colour for the
/// primary action of a screen.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.prominent = false,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.titleMedium;
    return _Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: GlassSurface.capsule(
        tint: prominent ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: text),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round glass icon button for toolbars (back, settings, close).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onPressed: onPressed,
        semanticLabel: tooltip,
        child: GlassSurface(
          shape: const CircleBorder(),
          floating: true,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}
