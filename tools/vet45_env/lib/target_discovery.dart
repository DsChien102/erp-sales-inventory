import 'dart:io';

import 'target_manifest.dart';
import 'workspace_manifest.dart';

/// Discovers and loads [vet45.target.json] files under the repo root.
class TargetDiscovery {
  TargetDiscovery({
    required this.rootDir,
    required this.scan,
  });

  final Directory rootDir;
  final ScanPolicy scan;

  /// Scan include patterns and return loaded targets keyed by id.
  ///
  /// Throws [StateError] on duplicate ids or zero targets found.
  Map<String, TargetManifest> discover() {
    final files = <File>{};
    for (final pattern in scan.include) {
      files.addAll(_globFiles(pattern));
    }

    final targets = <String, TargetManifest>{};
    for (final file in files) {
      final relative = _relativeToRoot(file.path);
      if (_isExcluded(relative)) {
        continue;
      }
      final manifest = TargetManifest.load(file);
      final existing = targets[manifest.id];
      if (existing != null) {
        throw StateError(
          'Duplicate target id "${manifest.id}":\n'
          '  ${existing.manifestFile.path}\n'
          '  ${manifest.manifestFile.path}',
        );
      }
      targets[manifest.id] = manifest;
    }

    if (targets.isEmpty) {
      throw StateError(
        'No ${TargetManifest.fileName} found under ${rootDir.path}. '
        'Expected apps/**/${TargetManifest.fileName} '
        'or .vet45/**/${TargetManifest.fileName}.',
      );
    }
    return targets;
  }

  Iterable<File> _globFiles(String pattern) {
    // Supported patterns: "<prefix>/**/<filename>" or exact relative path.
    final filename = TargetManifest.fileName;
    if (!pattern.endsWith(filename) && !pattern.endsWith('**/vet45.target.json')) {
      // Allow literal file paths relative to root.
      final file = File('${rootDir.path}/$pattern');
      if (file.existsSync()) {
        return [file];
      }
      return const [];
    }

    final roots = _rootsFromInclude(pattern);
    final results = <File>[];
    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }
      _collectTargetFiles(root, results);
    }
    return results;
  }

  List<Directory> _rootsFromInclude(String pattern) {
    // "apps/**/vet45.target.json" → scan under apps/
    // ".vet45/**/vet45.target.json" → scan under .vet45/
    final parts = pattern.split('/');
    final prefix = <String>[];
    for (final part in parts) {
      if (part == '**' || part == TargetManifest.fileName) {
        break;
      }
      prefix.add(part);
    }
    if (prefix.isEmpty) {
      return [rootDir];
    }
    return [Directory('${rootDir.path}/${prefix.join('/')}')];
  }

  void _collectTargetFiles(Directory dir, List<File> out) {
    final entities = dir.listSync(followLinks: false);
    for (final entity in entities) {
      final name = entity.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull;
      if (name == null) {
        continue;
      }
      if (entity is Directory) {
        if (name == '.dart_tool' || name == 'build' || name == '.git') {
          continue;
        }
        _collectTargetFiles(entity, out);
      } else if (entity is File && name == TargetManifest.fileName) {
        out.add(entity);
      }
    }
  }

  bool _isExcluded(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    for (final pattern in scan.exclude) {
      if (_matchesExclude(normalized, pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesExclude(String path, String pattern) {
    // Supports "**/.dart_tool/**" and "**/build/**".
    final cleaned = pattern
        .replaceAll('**/', '')
        .replaceAll('/**', '')
        .replaceAll('*', '');
    if (cleaned.isEmpty) {
      return false;
    }
    return path.contains('/$cleaned/') ||
        path.startsWith('$cleaned/') ||
        path.contains('/$cleaned');
  }

  String _relativeToRoot(String absolutePath) {
    final root = rootDir.path.endsWith(Platform.pathSeparator)
        ? rootDir.path
        : '${rootDir.path}${Platform.pathSeparator}';
    if (absolutePath.startsWith(root)) {
      return absolutePath.substring(root.length).replaceAll('\\', '/');
    }
    return absolutePath.replaceAll('\\', '/');
  }
}
