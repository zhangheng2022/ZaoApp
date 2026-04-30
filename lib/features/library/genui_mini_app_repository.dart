import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../genui_runtime/genui_mini_app_package.dart';

abstract interface class GenUiMiniAppRepository {
  Future<List<GenUiMiniAppPackage>> list();
  Future<GenUiMiniAppPackage?> findById(String id);
  Future<void> save(GenUiMiniAppPackage package);
}

class FileGenUiMiniAppRepository implements GenUiMiniAppRepository {
  FileGenUiMiniAppRepository({File? file}) : _file = file;

  final File? _file;

  Future<File> get _resolvedFile async {
    final injected = _file;
    if (injected != null) {
      return injected;
    }
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/mini_apps.json');
  }

  @override
  Future<List<GenUiMiniAppPackage>> list() async {
    final file = await _resolvedFile;
    if (!file.existsSync()) {
      return <GenUiMiniAppPackage>[];
    }

    final decoded = jsonDecode(await file.readAsString());
    final items = decoded is List ? decoded : const [];
    return items
        .whereType<Map>()
        .map((item) => GenUiMiniAppPackage.fromJson(Map<String, Object?>.from(item)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<GenUiMiniAppPackage?> findById(String id) async {
    for (final package in await list()) {
      if (package.id == id) {
        return package;
      }
    }
    return null;
  }

  @override
  Future<void> save(GenUiMiniAppPackage package) async {
    final file = await _resolvedFile;
    await file.parent.create(recursive: true);

    final packages = await list();
    final index = packages.indexWhere((item) => item.id == package.id);
    if (index == -1) {
      packages.add(package);
    } else {
      packages[index] = package;
    }

    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(packages.map((item) => item.toJson()).toList()),
    );
  }
}

final GenUiMiniAppRepository genUiMiniAppRepository =
    FileGenUiMiniAppRepository();
