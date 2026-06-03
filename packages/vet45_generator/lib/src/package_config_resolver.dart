import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

abstract final class PackageConfigResolver {
  static String findPackageRoot({
    required String packageName,
    required String fromDirectory,
  }) {
    var directory = Directory(fromDirectory).absolute;

    while (true) {
      final configFile = File(p.join(directory.path, '.dart_tool', 'package_config.json'));
      if (configFile.existsSync()) {
        final decoded = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = decoded['packages'] as List<dynamic>;
        for (final package in packages) {
          final map = package as Map<String, dynamic>;
          if (map['name'] == packageName) {
            final rootUri = map['rootUri'] as String;
            if (rootUri.startsWith('file:')) {
              return p.normalize(Uri.parse(rootUri).toFilePath());
            }
            return p.normalize(p.join(configFile.parent.path, rootUri));
          }
        }
      }

      final parent = directory.parent;
      if (parent.path == directory.path) {
        break;
      }
      directory = parent;
    }

    throw StateError('Package "$packageName" not found from $fromDirectory');
  }

  static List<String> listMatchingDartFiles({
    required String packageRoot,
    required List<String> scanGlobs,
  }) {
    final normalizedRoot = Directory(packageRoot).absolute;
    final libRoot = Directory(p.join(normalizedRoot.path, 'lib'));
    if (!libRoot.existsSync()) {
      return const [];
    }

    final files = <String>[];
    for (final entity in normalizedRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final relative = p.relative(entity.path, from: normalizedRoot.path).replaceAll('\\', '/');
      if (_matchesAnyGlob(relative, scanGlobs)) {
        files.add(p.normalize(entity.path));
      }
    }

    return files..sort();
  }

  static bool _matchesAnyGlob(String relativePath, List<String> scanGlobs) {
    for (final pattern in scanGlobs) {
      if (_matchesGlob(relativePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesGlob(String path, String pattern) {
    final normalized = pattern.replaceAll('\\', '/');
    if (!normalized.contains('*')) {
      return path == normalized;
    }

    final suffixStart = normalized.lastIndexOf('*');
    final prefix = normalized.substring(0, suffixStart).replaceAll('**/', '');
    final suffix = normalized.substring(suffixStart + 1);

    return path.startsWith(prefix) &&
        path.endsWith(suffix) &&
        !path.contains('/configurations/');
  }

  static String? packageNameForUri(Uri uri) {
    if (uri.scheme == 'package' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    if (uri.scheme != 'file') {
      return null;
    }

    final filePath = p.normalize(uri.toFilePath());
    return _packageNameForFilePath(filePath);
  }

  static String? packageNameFromImportUri(Object importUri) {
    final packageFromUri = packageNameForUri(
      importUri is Uri ? importUri : Uri.tryParse(importUri.toString()) ?? Uri(),
    );
    if (packageFromUri != null && packageFromUri.isNotEmpty) {
      return packageFromUri;
    }

    final match = RegExp(r'^package:([^/]+)/').firstMatch(importUri.toString());
    return match?.group(1);
  }

  static String? _packageNameForFilePath(String filePath) {
    var directory = Directory(filePath).parent;

    while (true) {
      final configFile = File(p.join(directory.path, '.dart_tool', 'package_config.json'));
      if (configFile.existsSync()) {
        final decoded = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = decoded['packages'] as List<dynamic>;
        for (final package in packages) {
          final map = package as Map<String, dynamic>;
          final name = map['name'] as String;
          final rootUri = map['rootUri'] as String;
          final rootPath = rootUri.startsWith('file:')
              ? p.normalize(Uri.parse(rootUri).toFilePath())
              : p.normalize(p.join(configFile.parent.path, rootUri));
          if (p.isWithin(rootPath, filePath) || p.equals(rootPath, filePath)) {
            return name;
          }
        }
      }

      final parent = directory.parent;
      if (parent.path == directory.path) {
        break;
      }
      directory = parent;
    }

    return null;
  }
}
