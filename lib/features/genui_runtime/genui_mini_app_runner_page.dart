import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../library/genui_mini_app_repository.dart';
import 'genui_mini_app_package.dart';
import 'genui_surface_runner.dart';

class GenUiMiniAppRunnerPage extends StatelessWidget {
  const GenUiMiniAppRunnerPage({
    required this.appId,
    required this.repository,
    super.key,
  });

  final String appId;
  final GenUiMiniAppRepository repository;

  @override
  Widget build(BuildContext context) => FScaffold(
    child: SafeArea(
      child: FutureBuilder<GenUiMiniAppPackage?>(
        future: repository.findById(appId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('正在打开小应用...'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('打开失败，请返回重试'));
          }
          final package = snapshot.data;
          if (package == null) {
            return const Center(child: Text('小应用不存在'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    FButton.icon(
                      onPress: () => context.go('/'),
                      child: const Icon(FIcons.chevronLeft),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        package.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GenUiSurfaceRunner(package: package),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
