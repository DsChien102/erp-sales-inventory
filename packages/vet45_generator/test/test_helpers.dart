import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves [vet45_generator] package root for tests run from repo root or package dir.
String resolveGeneratorPackageRoot() {
  final cwd = Directory.current.path;
  final cwdPubspec = File(p.join(cwd, 'pubspec.yaml'));
  if (cwdPubspec.existsSync() &&
      cwdPubspec.readAsStringSync().contains('name: vet45_generator')) {
    return p.normalize(cwd);
  }

  final fromRepo = p.join(cwd, 'packages', 'vet45_generator');
  if (File(p.join(fromRepo, 'pubspec.yaml')).existsSync()) {
    return p.normalize(fromRepo);
  }

  throw StateError('Could not find vet45_generator package root from $cwd');
}
