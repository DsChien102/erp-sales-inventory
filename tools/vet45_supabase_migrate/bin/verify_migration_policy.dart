import 'dart:io';

import 'package:vet45_supabase_migrate/migration_policy.dart';
import 'package:vet45_supabase_migrate/promote_drafts_service.dart';
import 'package:vet45_supabase_migrate/repo_root.dart';
import 'package:vet45_supabase_migrate/schema_lock.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final strict = args.contains('--strict');

  try {
    final repoRoot = Directory(findRepoRoot());
    final migrationsDir = Directory(
      '${repoRoot.path}/$migrationsRelativePath',
    );
    final lockFile = File('${repoRoot.path}/$schemaLockRelativePath');
    final schemaLock = SchemaLock.load(lockFile);

    final verifier = MigrationPolicyVerifier();
    final violations = verifier.verifyDirectory(
      migrationsDirectory: migrationsDir,
      options: MigrationPolicyOptions(
        strict: strict,
        schemaLock: schemaLock,
        repoRoot: repoRoot,
      ),
    );

    final errors =
        violations.where((v) => v.severity == PolicySeverity.error).toList();
    final warnings =
        violations.where((v) => v.severity == PolicySeverity.warning).toList();

    if (violations.isEmpty) {
      stdout.writeln('verify_migration_policy: OK (no violations)');
      exit(0);
    }

    stdout.writeln('verify_migration_policy: ${errors.length} error(s), ${warnings.length} warning(s)');
    stdout.writeln('');

    for (final violation in violations) {
      final label =
          violation.severity == PolicySeverity.error ? 'ERROR' : 'WARN';
      stdout.writeln('[$label] ${violation.file} (${violation.code})');
      stdout.writeln('  ${violation.message}');
      stdout.writeln('');
    }

    if (errors.isNotEmpty || (strict && warnings.isNotEmpty)) {
      exit(1);
    }

    stdout.writeln('Non-strict mode: warnings only, exiting 0');
    exit(0);
  } on Object catch (error) {
    stderr.writeln('verify_migration_policy error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart <options>

Validates cohesive migration policy on promoted files (skips bootstrap_grandfathered).
Also guards adopted objects (schema.lock) and generated region byte-match.

Options:
  --strict    Treat warnings as errors
  -h, --help  Show this help

Examples:
  dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart
  melos run migrate:verify-policy -- --strict
''');
}
