import 'dart:io';

import 'package:vet45_supabase_migrate/migration_registry.dart';
import 'package:vet45_supabase_migrate/promote_drafts_service.dart';
import 'package:vet45_supabase_migrate/repo_root.dart';
import 'package:vet45_supabase_migrate/seed_registry_service.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final write = args.contains('--write');
  final dryRun = !write;

  try {
    final repoRoot = Directory(findRepoRoot());
    final service = SeedRegistryService();
    final migrationsDir = Directory(
      '${repoRoot.path}/$migrationsRelativePath',
    );

    final result = service.seed(migrationsDirectory: migrationsDir);
    final registryFile = File('${repoRoot.path}/$registryRelativePath');

    stdout.writeln('Seed registry scan');
    stdout.writeln('==================');
    stdout.writeln('Migrations scanned: ${result.scannedFiles}');
    stdout.writeln('Functions indexed: ${result.functionCount}');
    stdout.writeln('Grandfathered migrations: ${result.registry.bootstrapGrandfathered.length}');
    stdout.writeln('');

    for (final schema in ['catalog', 'iam', 'platform']) {
      final count = result.registry.schemas[schema]?.length ?? 0;
      if (count > 0) {
        stdout.writeln('  $schema: $count functions');
      }
    }

    if (dryRun) {
      stdout.writeln('');
      stdout.writeln('Dry run — use --write to create ${registryFile.path}');
      exit(0);
    }

    result.registry.write(registryFile);
    stdout.writeln('');
    stdout.writeln('wrote ${registryFile.path}');
  } on Object catch (error) {
    stderr.writeln('seed_registry error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/vet45_supabase_migrate/bin/seed_registry.dart <options>

Scans promoted migrations and builds supabase/migrations/REGISTRY.yaml with
last-owning migration per RPC plus bootstrap_grandfathered catalog list.

Options:
  --dry-run   Print scan summary (default)
  --write     Write REGISTRY.yaml
  -h, --help  Show this help

Examples:
  dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --dry-run
  melos run migrate:seed-registry -- --write
''');
}
