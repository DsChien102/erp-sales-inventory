import 'dart:io';

import 'package:c45_supabase_migrate/promote_drafts_service.dart';
import 'package:c45_supabase_migrate/repo_root.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final dryRun = args.contains('--dry-run');
  final write = args.contains('--write');
  final force = args.contains('--force');
  final bundleIntent = args.contains('--bundle-intent');

  if (!dryRun && !write) {
    stderr.writeln('error: specify --dry-run or --write');
    _printUsage();
    exit(64);
  }

  String? startTimestamp;
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--start-timestamp' && index + 1 < args.length) {
      startTimestamp = args[index + 1];
    }
  }

  try {
    final repoRoot = Directory(findRepoRoot());
    final service = PromoteDraftsService();
    final result = service.promote(
      PromoteDraftsOptions(
        repoRoot: repoRoot,
        startTimestamp: startTimestamp,
        dryRun: dryRun,
        force: force,
        bundleIntent: bundleIntent,
      ),
    );

    _printPlan(
      outputDir: service.migrationsDir(repoRoot),
      planned: result.planned,
    );

    if (!dryRun) {
      for (final file in result.written) {
        stdout.writeln('wrote ${file.path}');
      }
    }
  } on Object catch (error) {
    stderr.writeln('promote_drafts error: $error');
    exit(1);
  }
}

void _printPlan({
  required Directory outputDir,
  required List<PlannedMigration> planned,
}) {
  stdout.writeln('Promotion plan');
  stdout.writeln('==============');
  stdout.writeln('Output directory: ${outputDir.path}');
  stdout.writeln('Migrations: ${planned.length}');
  stdout.writeln('');

  var totalLines = 0;
  for (final migration in planned) {
    totalLines += migration.lineCount;
    stdout.writeln('- ${migration.outputFileName}');
    if (migration.sourceDraftNames.length == 1) {
      stdout.writeln('  source: _drafts/${migration.sourceDraftNames.first}');
    } else {
      stdout.writeln('  sources:');
      for (final source in migration.sourceDraftNames) {
        stdout.writeln('    - _drafts/$source');
      }
    }
    stdout.writeln('  lines: ${migration.lineCount}');
    stdout.writeln('');
  }

  stdout.writeln('Total SQL lines: $totalLines');
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/c45_supabase_migrate/bin/promote_drafts.dart <options>

Promotes every .sql file in supabase/migrations/_drafts/ to timestamped files in
supabase/migrations/, preserving draft order (numeric prefix first).

Default migration ids use today's date (YYYYMMDD) plus a 3-digit daily sequence
(xxx), e.g. 20260709001. Existing migrations on the same day bump the sequence.

Options:
  --dry-run              Print the promotion plan without writing files
  --write                Write timestamped migration files
  --force                Overwrite existing migration files with the same name
  --bundle-intent        Merge drafts sharing _patch_<intent>_ into one migration
  --start-timestamp ID   11-digit migration id (YYYYMMDDxxx) for the first file
  -h, --help             Show this help

Examples:
  dart run tools/c45_supabase_migrate/bin/promote_drafts.dart --dry-run
  dart run tools/c45_supabase_migrate/bin/promote_drafts.dart --write
  melos run migrate:promote-drafts -- --dry-run
''');
}
