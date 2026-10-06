import 'dart:io';

import 'package:vet45_supabase_migrate/repo_root.dart';
import 'package:vet45_supabase_migrate/schema_lock_sync.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final strictFlag = args.contains('--strict');
  final warnOnlyFlag = args.contains('--warn-only');

  try {
    final repoRoot = Directory(findRepoRoot());
    final branch = detectCurrentBranch();
    final strict = strictFlag ||
        (!warnOnlyFlag && isPromoteOrReleaseBranch(branch));

    final diff = SchemaLockSyncChecker().check(repoRoot: repoRoot);
    if (diff.isSynced) {
      stdout.writeln('verify_schema_lock_sync: OK (sources match schema.lock.yaml)');
      exit(0);
    }

    final label = strict ? 'ERROR' : 'WARN';
    stdout.writeln(
      'verify_schema_lock_sync: lock not synced '
      '(branch=${branch ?? "unknown"}, mode=${strict ? "fail" : "warn"})',
    );
    for (final name in diff.added) {
      stdout.writeln('[$label] added (not in lock): $name');
    }
    for (final name in diff.changed) {
      stdout.writeln('[$label] changed (hash drift): $name');
    }
    for (final name in diff.removed) {
      stdout.writeln('[$label] removed (lock orphan): $name');
    }
    stdout.writeln('');
    stdout.writeln('Run: melos run migrate:generate -- <intent>');

    if (strict) {
      exit(1);
    }
    stdout.writeln('Non-strict / slice branch: warnings only, exiting 0');
    exit(0);
  } on Object catch (error) {
    stderr.writeln('verify_schema_lock_sync error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart [options]

Compares declarative SQL sources to supabase/schema.lock.yaml.

On promote/release branches (main, master, release/*, promote/*) or with
--strict, unsynced lock fails. On slice branches, prints warnings and exits 0.

Options:
  --strict      Always fail when unsynced
  --warn-only   Always warn (never fail), even on promote/release
  -h, --help    Show this help
''');
}
