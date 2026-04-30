import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zaoapp/features/library/genui_mini_app_repository.dart';

import '../genui_runtime/genui_test_fixtures.dart';

void main() {
  test('saves reads and overwrites packages by id', () async {
    final directory = await Directory.systemTemp.createTemp('zaoapp_repo_test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileGenUiMiniAppRepository(
      file: File('${directory.path}/mini_apps.json'),
    );

    await repository.save(validPackage(id: 'same', name: '旧名称'));
    await repository.save(validPackage(id: 'same', name: '新名称'));

    final packages = await repository.list();

    expect(packages, hasLength(1));
    expect(packages.single.id, 'same');
    expect(packages.single.name, '新名称');
  });
}
