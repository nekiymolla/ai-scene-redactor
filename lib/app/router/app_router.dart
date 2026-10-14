import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/generation/presentation/processing_screen.dart';
import '../../features/generation/presentation/result_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/project_creation/presentation/characters_screen.dart';
import '../../features/project_creation/presentation/create_project_screen.dart';
import '../../features/project_creation/presentation/describe_screen.dart';
import '../../features/project_creation/presentation/review_screen.dart';
import '../../features/projects/presentation/project_details_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_routes.dart';

/// Every screen is nested under Home, so deep links and `go()` always build
/// a stack with Home at the bottom and the back button has somewhere to go.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: 'projects/:id',
            builder: (_, state) =>
                ProjectDetailsScreen(projectId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'processing',
                builder: (_, state) =>
                    ProcessingScreen(projectId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'result',
                builder: (_, state) =>
                    ResultScreen(projectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'create',
            builder: (_, _) => const CreateProjectScreen(),
            routes: [
              GoRoute(
                path: 'characters',
                builder: (_, _) => const CharactersScreen(),
              ),
              GoRoute(
                path: 'describe',
                builder: (_, _) => const DescribeScreen(),
              ),
              GoRoute(path: 'review', builder: (_, _) => const ReviewScreen()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
