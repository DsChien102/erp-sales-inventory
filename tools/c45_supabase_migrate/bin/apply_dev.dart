import 'dart:io';

import 'package:c45_supabase_migrate/apply_dev_service.dart';
import 'package:c45_supabase_migrate/apply_dev_target.dart';
import 'package:c45_supabase_migrate/repo_root.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final yes = args.contains('--yes') || args.contains('-y');

  try {
    final repoRoot = Directory(findRepoRoot());
    final target = resolveApplyDevTarget(repoRoot);
    final databaseUrl = resolveDatabaseUrl(repoRoot, target);
    if (databaseUrl == null || databaseUrl.isEmpty) {
      stderr.writeln(
        'error: set DATABASE_URL (or SUPABASE_DB_URL) in '
        '.c45/profiles/${target.profileId}/${target.environmentId}.env',
      );
      exit(1);
    }

    final service = ApplyDevService(executor: PsqlSqlExecutor(databaseUrl));
    service.assertEnvironmentAllowed(target.environmentId);

    late final ApplyDevResult result;
    try {
      result = await service.apply(
        ApplyDevOptions(
          repoRoot: repoRoot,
          target: target,
          confirmed: yes,
        ),
      );
    } on ApplyDevConfirmationRequired catch (pending) {
      stdout.writeln('schema:apply-dev');
      stdout.writeln(
        '  profile: ${pending.target.profileId}/${pending.target.environmentId}',
      );
      stdout.writeln('  project: ${pending.target.projectRef}');
      stdout.writeln('  objects (${pending.objects.length}):');
      for (final object in pending.objects) {
        stdout.writeln('    - ${object.qualifiedName}');
      }
      stdout.writeln();
      stdout.write('Apply these objects? [y/N] ');
      final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (answer != 'y' && answer != 'yes') {
        stdout.writeln('Aborted.');
        exit(0);
      }
      result = await service.apply(
        ApplyDevOptions(
          repoRoot: repoRoot,
          target: target,
          confirmed: true,
        ),
      );
    }

    if (result.applied.isEmpty) {
      stdout.writeln('schema:apply-dev: nothing to apply '
          '(${result.skipped.length} already match apply log)');
    } else {
      stdout.writeln('schema:apply-dev: applied ${result.applied.length} object(s):');
      for (final name in result.applied) {
        stdout.writeln('  - $name');
      }
      if (result.skipped.isNotEmpty) {
        stdout.writeln('skipped ${result.skipped.length} unchanged');
      }
    }
  } on ApplyDevException catch (error) {
    stderr.writeln('schema:apply-dev error: $error');
    exit(1);
  } on Object catch (error) {
    stderr.writeln('schema:apply-dev error: $error');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/c45_supabase_migrate/bin/apply_dev.dart [options]

Applies declarative SQL sources whose hash differs from
c45_dev.schema_apply_log on the active c45 profile database.

Does not run draft pre/post regions. Always refuses staging/production.

Options:
  -y, --yes   Skip interactive confirmation
  -h, --help  Show this help

Requires DATABASE_URL (or SUPABASE_DB_URL) in the active profile env file,
plus SUPABASE_PROJECT_REF or SUPABASE_URL for the confirm banner.

Examples:
  melos run schema:apply-dev
  melos run schema:apply-dev -- --yes
''');
}
