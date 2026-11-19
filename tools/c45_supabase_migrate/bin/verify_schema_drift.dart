import 'dart:io';

import 'package:c45_supabase_migrate/apply_dev_service.dart';
import 'package:c45_supabase_migrate/apply_dev_target.dart';
import 'package:c45_supabase_migrate/repo_root.dart';
import 'package:c45_supabase_migrate/schema_drift_service.dart';
import 'package:c45_supabase_migrate/sql_source_discovery.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  String? databaseUrl;
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--database-url') {
      if (index + 1 >= args.length) {
        stderr.writeln('error: --database-url requires a value');
        exit(64);
      }
      databaseUrl = args[++index];
    } else if (arg.startsWith('--database-url=')) {
      databaseUrl = arg.substring('--database-url='.length);
    } else if (arg.startsWith('-')) {
      stderr.writeln('error: unknown option $arg');
      _printUsage();
      exit(64);
    } else {
      stderr.writeln('error: unexpected argument $arg');
      _printUsage();
      exit(64);
    }
  }

  try {
    final repoRoot = Directory(findRepoRoot());
    databaseUrl ??= _databaseUrlFromEnv() ?? _databaseUrlFromProfile(repoRoot);
    if (databaseUrl == null || databaseUrl.isEmpty) {
      stderr.writeln(
        'error: pass --database-url or set DATABASE_URL / SUPABASE_DB_URL',
      );
      exit(1);
    }

    final result = await SchemaDriftService(
      executor: PsqlSqlExecutor(databaseUrl),
    ).check(repoRoot);

    if (result.isClean) {
      stdout.writeln(
        'schema:verify-drift: OK '
        '(${result.matched.length} declarative object(s) match DB)',
      );
      exit(0);
    }

    stderr.writeln(
      'schema:verify-drift: FAILED '
      '(${result.mismatches.length} mismatch(es))',
    );
    for (final mismatch in result.mismatches) {
      stderr.writeln('  - $mismatch');
    }
    exit(1);
  } on SchemaSourceException catch (error) {
    stderr.writeln('schema:verify-drift error: $error');
    exit(1);
  } on Object catch (error) {
    stderr.writeln('schema:verify-drift error: $error');
    exit(1);
  }
}

String? _databaseUrlFromEnv() {
  for (final key in const [
    'DATABASE_URL',
    'SUPABASE_DB_URL',
    'SUPABASE_DATABASE_URL',
  ]) {
    final value = Platform.environment[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _databaseUrlFromProfile(Directory repoRoot) {
  try {
    final target = resolveApplyDevTarget(repoRoot);
    return resolveDatabaseUrl(repoRoot, target);
  } on ApplyDevException {
    return null;
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/c45_supabase_migrate/bin/verify_schema_drift.dart [options]

Compares declarative SQL sources with live Postgres definitions.
Run after `supabase db reset` in CI.

Options:
  --database-url <uri>   Postgres connection URI (or set DATABASE_URL)
  -h, --help             Show this help

Examples:
  melos run schema:verify-drift -- --database-url "\$DATABASE_URL"
  ./scripts/ci/verify_schema_drift.sh
''');
}
