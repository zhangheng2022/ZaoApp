import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/generator/config_generation_service.dart';
import '../features/generator/generator_page.dart';
import '../features/generator/mock_config_generation_service.dart';
import '../features/library/app_library_page.dart';

abstract final class AppRouteNames {
  static const library = 'library';
  static const generator = 'generator';
}

abstract final class AppRoutePaths {
  static const library = '/';
  static const generator = '/generate';
}

GoRouter createAppRouter({
  ConfigGenerationService generatorService =
      const MockConfigGenerationService(),
}) => GoRouter(
  initialLocation: AppRoutePaths.library,
  routes: [
    GoRoute(
      path: AppRoutePaths.library,
      name: AppRouteNames.library,
      builder: (context, state) => const AppLibraryPage(),
    ),
    GoRoute(
      path: AppRoutePaths.generator,
      name: AppRouteNames.generator,
      builder: (context, state) => GeneratorPage(service: generatorService),
    ),
  ],
  errorBuilder: (context, state) =>
      const FScaffold(child: Center(child: Text('Page not found'))),
);

final GoRouter appRouter = createAppRouter();
