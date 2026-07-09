import 'dart:io';

import 'repo_root.dart';

class ConfigInitResult {
  ConfigInitResult({
    required this.created,
    required this.skipped,
  });

  final List<String> created;
  final List<String> skipped;

  bool get alreadyInitialized => created.isEmpty && skipped.isNotEmpty;
}

/// Scaffolds local `config/` from bundled templates on first-time setup.
class ConfigInitService {
  ConfigInitService({Directory? repoRoot})
      : repoRoot = repoRoot ?? Directory(findRepoRoot());

  final Directory repoRoot;

  static String templatesDir(Directory root) =>
      '${root.path}/tools/vet45_env/templates/config';

  bool get isInitialized =>
      File('${repoRoot.path}/config/environments.json').existsSync();

  Future<ConfigInitResult> init({bool force = false}) async {
    final templates = Directory(templatesDir(repoRoot));
    if (!templates.existsSync()) {
      throw StateError(
        'Missing config templates at ${templates.path}. '
        'Run melos bootstrap from the Vet45 monorepo root.',
      );
    }

    if (isInitialized && !force) {
      throw StateError(
        'Config already initialized at ${repoRoot.path}/config. '
        'Use --force to refresh scaffold files (never overwrites filled *.env secrets).',
      );
    }

    final created = <String>[];
    final skipped = <String>[];

    await for (final entity in templates.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relative = _relativePath(templates.path, entity.path);
      final dest = File('${repoRoot.path}/config/$relative');
      if (dest.existsSync() && !_shouldOverwrite(dest.path, force: force)) {
        skipped.add(relative);
        continue;
      }
      dest.parent.createSync(recursive: true);
      await dest.writeAsBytes(await entity.readAsBytes());
      created.add(relative);
    }

    return ConfigInitResult(created: created, skipped: skipped);
  }

  static bool _shouldOverwrite(String destPath, {required bool force}) {
    if (!force) {
      return false;
    }
    if (_isFilledSecretEnv(destPath)) {
      return false;
    }
    return true;
  }

  static bool _isFilledSecretEnv(String path) {
    if (!path.endsWith('.env')) {
      return false;
    }
    if (path.endsWith('.env.example')) {
      return false;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return false;
    }
    final content = file.readAsStringSync().trim();
    if (content.isEmpty) {
      return false;
    }
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final eq = trimmed.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final value = trimmed.substring(eq + 1).trim();
      if (value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static String _relativePath(String root, String filePath) {
    final normalizedRoot = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    if (!filePath.startsWith(normalizedRoot)) {
      return filePath;
    }
    return filePath.substring(normalizedRoot.length);
  }
}

void requireConfigInitialized(Directory repoRoot) {
  if (ConfigInitService(repoRoot: repoRoot).isInitialized) {
    return;
  }
  stderr.writeln('Vet45 config is not initialized.');
  stderr.writeln('');
  stderr.writeln('First-time setup:');
  stderr.writeln('  melos bootstrap');
  stderr.writeln('  melos run env:init');
  stderr.writeln('');
  stderr.writeln('Then copy and fill secrets, e.g.:');
  stderr.writeln(
    '  cp config/secrets/development.env.example config/secrets/development.env',
  );
  exit(1);
}
