import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Entry of the creation flow. Media picking arrives in stage 2 (P2-02..P2-04);
/// until then the screen says so plainly instead of showing inert controls.
class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый проект')),
      body: const Center(
        child: StateView(
          icon: Icons.construction_outlined,
          title: 'Экран в разработке',
          message:
              'Выбор исходного видео и фото персонажей появится на этапе 2.',
        ),
      ),
    );
  }
}
