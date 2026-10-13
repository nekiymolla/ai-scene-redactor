import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/glass/glass_back_button.dart';
import '../../../core/widgets/glass/glass_scaffold.dart';
import '../../../core/widgets/glass/glass_surface.dart';
import '../../../core/widgets/state_views.dart';

/// Entry of the creation flow. Media picking arrives in stage 2 (P2-02..P2-04);
/// until then the screen says so plainly instead of showing inert controls.
class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      title: 'Новый проект',
      leading: GlassBackButton(),
      slivers: [
        SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(
            child: GlassSurface(
              child: StateView(
                icon: Icons.construction_outlined,
                title: 'Экран в разработке',
                message:
                    'Выбор исходного видео и фото персонажей появится на этапе 2.',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
