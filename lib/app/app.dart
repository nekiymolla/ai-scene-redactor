import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AI Scene Changer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
