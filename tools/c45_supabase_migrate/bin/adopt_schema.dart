import 'dart:io';

import 'package:c45_supabase_migrate/adopt_schema_service.dart';
import 'package:c45_supabase_migrate/repo_root.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  String? module;
  final positional = <String>[];
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--module') {
      if (index + 1 >= args.length) {
        stderr.writeln('error: --module requires a value');
        exit(64);
      }
      module = args[++index];
    } else if (arg.startsWith('-')) {
      stderr.writeln('error: unknown option $arg');
      _printUsage();
      exit(64);
    } else {
      positional.add(arg);
    }
  }

  if ((module == null) == (positional.isEmpty)) {
    stderr.writeln(
      'error: specify exactly one of <schema.object> or --module <name>',
    );
    _printUsage();
    exit(64);
  }
  if (positional.length > 1) {
    stderr.writeln('error: specify at most one <schema.object>');
    _printUsage();
    exit(64);
  }

  try {
    final result = AdoptSchemaService().adopt(
      AdoptSchemaOptions(
        repoRoot: Directory(findRepoRoot()),
        qualifiedName: positional.isEmpty ? null : positional.single,
        module: module,
      ),
    );

    stdout.writeln('Adopted ${result.adopted.length} object(s):');
    for (final name in result.adopted) {
      stdout.writeln('- $name');
    }
    stdout.writeln('updated supabase/schema.lock.yaml');
    stdout.writeln('updated supabase/migrations/REGISTRY.yaml');
  } on AdoptSchemaException catch (error) {
    stderr.writeln('adopt_schema error: ${error.message}');
    exit(1);
  } on Object catch (error) {
    stderr.writeln('adopt_schema error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tools/c45_supabase_migrate/bin/adopt_schema.dart <schema.object>
  dart run tools/c45_supabase_migrate/bin/adopt_schema.dart --module <name>

Cuts function definitions from the migration pointed by REGISTRY.yaml, writes
declarative source files + schema.lock.yaml entries (last_migration = source
migration), and removes the REGISTRY entries. Does not generate a migration.

Sources written to:
  modules/<module>/infrastructure/supabase/sql/functions/<name>.sql
  supabase/sql/<schema>/functions/<name>.sql   (when modules/<schema> is absent)

Options:
  --module <name>   Adopt every REGISTRY function under schema <name>
  -h, --help        Show this help

Examples:
  melos run schema:adopt -- catalog.search_products
  melos run schema:adopt -- --module catalog
''');
}
