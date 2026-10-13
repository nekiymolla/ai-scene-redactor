import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import 'ambient_background.dart';

/// Screen layout in the iOS 26 style: content scrolls edge to edge under
/// floating glass controls, with a large title at the top of the content.
///
/// Every screen owns its own [AmbientBackground] so that page transitions
/// never show the previous page through a transparent one.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottomAction,
  });

  final String title;

  /// Small line above the title, e.g. the wizard step.
  final String? subtitle;
  final List<Widget> slivers;

  /// Top-left floating control, usually a back button.
  final Widget? leading;
  final List<Widget> actions;

  /// Floating control in the thumb zone, usually the primary action.
  final Widget? bottomAction;

  static const _toolbarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final bottomInset = bottomAction == null
        ? padding.bottom + AppSpacing.lg
        : padding.bottom + 56 + AppSpacing.md * 2 + AppSpacing.lg;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          Positioned.fill(
            child: BackdropGroup(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: AppSpacing.page.copyWith(
                      top: padding.top + _toolbarHeight + AppSpacing.sm,
                      bottom: AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...slivers,
                  SliverPadding(padding: EdgeInsets.only(bottom: bottomInset)),
                ],
              ),
            ),
          ),
          // Scrims keep floating controls legible over scrolled content.
          _Scrim(
            height: padding.top + _toolbarHeight + AppSpacing.lg,
            top: true,
          ),
          if (bottomAction != null) _Scrim(height: bottomInset, top: false),
          Positioned(
            top: padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              children: [
                ?leading,
                const Spacer(),
                for (final a in actions) ...[
                  const SizedBox(width: AppSpacing.sm),
                  a,
                ],
              ],
            ),
          ),
          if (bottomAction != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: padding.bottom + AppSpacing.md,
              child: bottomAction!,
            ),
        ],
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.height, required this.top});

  final double height;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.background.withValues(alpha: 0.95),
      AppColors.background.withValues(alpha: 0.75),
      AppColors.background.withValues(alpha: 0),
    ];
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: colors,
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}
