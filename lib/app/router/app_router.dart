import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/project_creation/presentation/create_project_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.create,
        builder: (_, _) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
