import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass_buttons.dart';

/// Floating back control for [GlassScaffold.leading]. Renders nothing on a
/// root route. The iOS edge-swipe back gesture keeps working as usual.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.canPop()) return const SizedBox.shrink();
    return GlassIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      tooltip: 'Назад',
      onPressed: () => context.pop(),
    );
  }
}
