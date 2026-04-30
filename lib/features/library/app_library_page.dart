import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class AppLibraryPage extends StatelessWidget {
  const AppLibraryPage({super.key});

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
                  spacing: 20,
                  children: [
                    const _LibraryHeader(),
                    _EmptyLibraryState(onCreate: () => context.go('/generate')),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text('我的小应用', style: Theme.of(context).textTheme.headlineSmall),
      Text('保存、打开和继续修改你生成的小应用。', style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => FCard(
    title: Row(
      spacing: 10,
      children: [
        const Icon(FIcons.library),
        Text('还没有小应用', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
    subtitle: const Text('描述一个待办、习惯、倒计时或记账工具，ZaoApp 会生成可预览的 JSON 配置。'),
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
