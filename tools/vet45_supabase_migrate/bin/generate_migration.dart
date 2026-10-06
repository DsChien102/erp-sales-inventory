import 'dart:io';

import 'package:vet45_supabase_migrate/generate_migration_service.dart';
import 'package:vet45_supabase_migrate/repo_root.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  var dryRun = false;
  String? startTimestamp;
  final positional = <String>[];
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--start-timestamp') {
      if (index + 1 >= args.length) {
        stderr.writeln('error: --start-timestamp requires a value');
        exit(64);
      }
      startTimestamp = args[++index];
    } else if (arg.startsWith('-')) {
      stderr.writeln('error: unknown option $arg');
      _printUsage();
      exit(64);
    } else {
      positional.add(arg);
    }
  }

  if (positional.length != 1) {
    stderr.writeln('error: specify exactly one <intent>');
    _printUsage();
    exit(64);
  }

  try {
    final repoRoot = Directory(findRepoRoot());
    final result = GenerateMigrationService().generate(
      GenerateMigrationOptions(
        repoRoot: repoRoot,
        intent: positional.single,
        startTimestamp: startTimestamp,
        dryRun: dryRun,
      ),
    );

    final migration = result.migration;
    if (migration == null) {
      stdout.writeln('No declarative SQL source changed; nothing to generate.');
      return;
    }

    stdout.writeln(dryRun ? 'Would generate' : 'Generated');
    stdout.writeln('- ${migration.fileName}');
    for (final name in migration.touches) {
      stdout.writeln('  touches: $name');
    }
    if (result.written case final file?) {
      stdout.writeln('wrote ${file.path}');
      stdout.writeln('updated supabase/schema.lock.yaml');
    }
  } on ArgumentError catch (error) {
    stderr.writeln('generate_migration error: ${error.message}');
    exit(64);
  } on Object catch (error) {
    stderr.writeln('generate_migration error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/vet45_supabase_migrate/bin/generate_migration.dart <intent> [options]

Compares declarative SQL sources with supabase/schema.lock.yaml and writes
one Kind: generated migration containing only new or changed objects
(functions, views, triggers, policies), then updates the lock. Writes nothing
when every source matches the lock.

Sources:
  modules/<module>/infrastructure/supabase/sql/{functions,views,triggers,policies}/<name>.sql
  supabase/sql/<schema>/{functions,views,triggers,policies}/<name>.sql

Regions (fixed order, name-sorted within each):
  functions → views → triggers → policies

Triggers and policies are wrapped with drop ... if exists before create.

Options:
  --dry-run              Print the plan without writing the migration or lock
  --start-timestamp ID   11-digit migration id (YYYYMMDDxxx)
  -h, --help             Show this help

Examples:
  melos run migrate:generate -- catalog_search_tweak --dry-run
  melos run migrate:generate -- catalog_search_tweak
''');
}
