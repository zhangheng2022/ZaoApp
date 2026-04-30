import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../genui_runtime/genui_mini_app_package.dart';
import 'genui_mini_app_repository.dart';

class AppLibraryPage extends StatefulWidget {
  const AppLibraryPage({required this.repository, super.key});

  final GenUiMiniAppRepository repository;

  @override
  State<AppLibraryPage> createState() => _AppLibraryPageState();
}

class _AppLibraryPageState extends State<AppLibraryPage> {
  late Future<List<GenUiMiniAppPackage>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.list();
  }

  @override
  Widget build(BuildContext context) => FScaffold(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 700 ? 32.0 : 16.0;
          final maxWidth = constraints.maxWidth >= 700
              ? 720.0
              : double.infinity;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LibraryHeader(),
                    const SizedBox(height: 20),
                    FutureBuilder<List<GenUiMiniAppPackage>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _LoadingLibraryState();
                        }
                        if (snapshot.hasError) {
                          return _ErrorLibraryState(onRetry: _reload);
                        }
                        final packages = snapshot.data ?? const [];
                        if (packages.isEmpty) {
                          return _EmptyLibraryState(
                            onCreate: () => context.go('/generate'),
                          );
                        }
                        return _PackageList(packages: packages);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  void _reload() {
    setState(() => _future = widget.repository.list());
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('我的小应用', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '保存、打开和继续修改你生成的 GenUI 小应用。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      FButton(
        size: .lg,
        onPress: () => context.go('/generate'),
        prefix: const Icon(FIcons.plus),
        child: const Text('创建'),
      ),
    ],
  );
}

class _PackageList extends StatelessWidget {
  const _PackageList({required this.packages});

  final List<GenUiMiniAppPackage> packages;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final package in packages) ...[
        _PackageTile(package: package),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package});

  final GenUiMiniAppPackage package;

  @override
  Widget build(BuildContext context) => FCard(
    title: Text(package.name, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(package.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FButton(
        size: .lg,
        variant: .outline,
        onPress: () => context.go('/apps/${package.id}'),
        child: const Text('打开'),
      ),
    ),
  );
}

class _LoadingLibraryState extends StatelessWidget {
  const _LoadingLibraryState();

  @override
  Widget build(BuildContext context) => const Center(child: Text('正在加载小应用...'));
}

class _ErrorLibraryState extends StatelessWidget {
  const _ErrorLibraryState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FCard(
    title: Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
    subtitle: const Text('无法读取本地 mini_apps.json。'),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FButton(
        size: .lg,
        variant: .outline,
        onPress: onRetry,
        child: const Text('重试'),
      ),
    ),
  );
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => FCard(
    title: Row(
      children: [
        const Icon(FIcons.library),
        const SizedBox(width: 10),
        Text('还没有小应用', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
    subtitle: const Text('描述一个工具，ZaoApp 会生成可预览、可保存的 GenUI surface。'),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FButton(
        size: .lg,
        onPress: onCreate,
        prefix: const Icon(FIcons.plus),
        child: const Text('创建小应用'),
      ),
    ),
  );
}
