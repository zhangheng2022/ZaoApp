import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/generator/generator_page.dart';
import '../features/generator/genui_generation_service.dart';
import '../features/generator/mock_genui_generation_service.dart';
import '../features/genui_runtime/genui_mini_app_runner_page.dart';
import '../features/library/app_library_page.dart';
import '../features/library/genui_mini_app_repository.dart';

abstract final class AppRouteNames {
  static const library = 'library';
  static const generator = 'generator';
  static const miniApp = 'miniApp';
}

abstract final class AppRoutePaths {
  static const library = '/';
  static const generator = '/generate';
  static const miniApp = '/apps/:appId';
}

GoRouter createAppRouter({
  GenUiGenerationService generatorService = const MockGenUiGenerationService(),
  GenUiMiniAppRepository? repository,
}) {
  final effectiveRepository = repository ?? genUiMiniAppRepository;
  return GoRouter(
    initialLocation: AppRoutePaths.library,
    routes: [
      GoRoute(
        path: AppRoutePaths.library,
        name: AppRouteNames.library,
        builder: (context, state) =>
            AppLibraryPage(repository: effectiveRepository),
      ),
      GoRoute(
        path: AppRoutePaths.generator,
        name: AppRouteNames.generator,
        builder: (context, state) => GeneratorPage(
          service: generatorService,
          repository: effectiveRepository,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.miniApp,
        name: AppRouteNames.miniApp,
        builder: (context, state) => GenUiMiniAppRunnerPage(
          appId: state.pathParameters['appId'] ?? '',
          repository: effectiveRepository,
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        const FScaffold(child: Center(child: Text('Page not found'))),
  );
}

final GoRouter appRouter = createAppRouter();
