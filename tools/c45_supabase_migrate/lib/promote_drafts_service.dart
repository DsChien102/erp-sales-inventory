import 'dart:io';

import 'migration_header.dart';

const draftsRelativePath = 'supabase/migrations/_drafts';
const migrationsRelativePath = 'supabase/migrations';

const migrationIdLength = 11;
const migrationDateLength = 8;
const migrationSequenceLength = 3;
const maxDailyMigrationSequence = 999;

final _draftOrderPrefix = RegExp(r'^(\d+)_(.+)$');
final _migrationIdPrefix = RegExp(r'^(\d{11})_');

class PromoteDraftsOptions {
  const PromoteDraftsOptions({
    required this.repoRoot,
    this.startTimestamp,
    this.referenceTime,
    this.dryRun = false,
    this.force = false,
    this.bundleIntent = false,
  });

  final Directory repoRoot;
  final String? startTimestamp;

  /// Defaults to [DateTime.now] when allocating date-based timestamps.
  final DateTime? referenceTime;
  final bool dryRun;
  final bool force;

  /// When true, drafts sharing `_patch_<intent>_` in the filename merge into one migration.
  final bool bundleIntent;
}

class PlannedMigration {
  const PlannedMigration({
    required this.timestamp,
    required this.outputFileName,
    required this.sourceDraftNames,
    required this.sql,
  });

  final String timestamp;
  final String outputFileName;
  final List<String> sourceDraftNames;
  final String sql;

  String get sourceDraftName => sourceDraftNames.first;

  int get lineCount => sql.split('\n').length;
}

class PromoteDraftsResult {
  const PromoteDraftsResult({
    required this.planned,
    required this.written,
  });

  final List<PlannedMigration> planned;
  final List<File> written;
}

class PromoteDraftsService {
  Directory draftsDir(Directory repoRoot) =>
      Directory('${repoRoot.path}/$draftsRelativePath');

  Directory migrationsDir(Directory repoRoot) =>
      Directory('${repoRoot.path}/$migrationsRelativePath');

  List<File> listDraftSqlFiles(Directory draftsDirectory) {
    if (!draftsDirectory.existsSync()) {
      throw StateError('Drafts directory not found: ${draftsDirectory.path}');
    }

    final drafts = draftsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList();

    drafts.sort((a, b) => _compareDraftFiles(a.path, b.path));
    return drafts;
  }

  String migrationSlug(String draftFileName) {
    final baseName = _basename(draftFileName).replaceAll('.sql', '');
    final match = _draftOrderPrefix.firstMatch(baseName);
    return match?.group(2) ?? baseName;
  }

  int? draftOrderNumber(String draftFileName) {
    final baseName = _basename(draftFileName).replaceAll('.sql', '');
    final match = _draftOrderPrefix.firstMatch(baseName);
    return match == null ? null : int.parse(match.group(1)!);
  }

  String migrationDatePrefix(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  int maxMigrationSequenceOnDate(
    Directory migrationsDirectory,
    String datePrefix,
  ) {
    if (!migrationsDirectory.existsSync()) {
      return 0;
    }

    var maxSequence = 0;
    for (final entry in migrationsDirectory.listSync()) {
      if (entry is! File || !entry.path.endsWith('.sql')) {
        continue;
      }

      final match = _migrationIdPrefix.firstMatch(_basename(entry.path));
      if (match == null) {
        continue;
      }

      final migrationId = match.group(1)!;
      if (!migrationId.startsWith(datePrefix)) {
        continue;
      }

      final sequence = int.tryParse(
        migrationId.substring(migrationDateLength, migrationIdLength),
      );
      if (sequence != null && sequence > maxSequence) {
        maxSequence = sequence;
      }
    }

    return maxSequence;
  }

  List<String> allocateTimestamps({
    required int count,
    required Directory migrationsDirectory,
    String? startTimestamp,
    DateTime? referenceTime,
  }) {
    if (count <= 0) {
      return const [];
    }

    if (startTimestamp != null) {
      final base = _parseMigrationId(startTimestamp);
      return List.generate(count, (index) {
        final next = base + index;
        return _formatMigrationId(next);
      });
    }

    final datePrefix = migrationDatePrefix(referenceTime ?? DateTime.now());
    final baseSequence =
        maxMigrationSequenceOnDate(migrationsDirectory, datePrefix) + 1;

    return List.generate(count, (index) {
      final sequence = baseSequence + index;
      if (sequence > maxDailyMigrationSequence) {
        throw StateError(
          'Daily migration limit ($maxDailyMigrationSequence) exceeded for $datePrefix',
        );
      }

      return _formatMigrationId(
        int.parse(
          '$datePrefix${sequence.toString().padLeft(migrationSequenceLength, '0')}',
        ),
      );
    });
  }

  String _formatMigrationId(int value) {
    return value.toString().padLeft(migrationIdLength, '0');
  }

  /// Returns bundle key for `NNN_<scope>_patch_<intent>_<part>.sql`, else null.
  String? bundleIntentKey(String draftFileName) {
    final slug = migrationSlug(draftFileName);
    final patchMarker = '_patch_';
    final patchIdx = slug.indexOf(patchMarker);
    if (patchIdx < 0) {
      return null;
    }

    final scope = slug.substring(0, patchIdx);
    final afterPatch = slug.substring(patchIdx + patchMarker.length);
    final lastUnderscore = afterPatch.lastIndexOf('_');
    if (lastUnderscore <= 0) {
      return null;
    }

    final intent = afterPatch.substring(0, lastUnderscore);
    return '${scope}_patch_$intent';
  }

  String buildSql({
    required String draftContent,
    required List<String> sourceDraftNames,
    MigrationHeader? header,
  }) {
    final body = stripHeaderComments(draftContent).trimRight();
    final headerBlock = header?.toCommentBlock(
          extraPromotedFrom: sourceDraftNames,
        ) ??
        sourceDraftNames
            .map((name) => '-- Promoted from _drafts/$name')
            .join('\n');

    return '''
$headerBlock
-- Generated by tools/c45_supabase_migrate/bin/promote_drafts.dart

$body
''';
  }

  List<PlannedMigration> plan(PromoteDraftsOptions options) {
    final drafts = listDraftSqlFiles(draftsDir(options.repoRoot));
    if (drafts.isEmpty) {
      throw StateError('No .sql drafts found in ${draftsDir(options.repoRoot).path}');
    }

    final groups = _groupDrafts(drafts, bundleIntent: options.bundleIntent);
    final timestamps = allocateTimestamps(
      count: groups.length,
      migrationsDirectory: migrationsDir(options.repoRoot),
      startTimestamp: options.startTimestamp,
      referenceTime: options.referenceTime,
    );

    final planned = <PlannedMigration>[];
    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final sourceDraftNames =
          group.map((draft) => _basename(draft.path)).toList();
      final timestamp = timestamps[index];

      final mergedHeader = _mergeHeaders(group);
      final mergedBody = group
          .map((draft) => stripHeaderComments(draft.readAsStringSync()))
          .where((body) => body.trim().isNotEmpty)
          .join('\n\n')
          .trimRight();

      final outputSlug = options.bundleIntent && group.length > 1
          ? bundleIntentKey(sourceDraftNames.first) ?? migrationSlug(sourceDraftNames.first)
          : migrationSlug(sourceDraftNames.first);

      final sql = buildSql(
        draftContent: mergedBody,
        sourceDraftNames: sourceDraftNames,
        header: mergedHeader,
      );

      planned.add(
        PlannedMigration(
          timestamp: timestamp,
          outputFileName: '${timestamp}_$outputSlug.sql',
          sourceDraftNames: sourceDraftNames,
          sql: sql,
        ),
      );
    }

    return planned;
  }

  List<List<File>> _groupDrafts(List<File> drafts, {required bool bundleIntent}) {
    if (!bundleIntent) {
      return drafts.map((draft) => [draft]).toList();
    }

    final groups = <String, List<File>>{};
    final order = <String>[];

    for (final draft in drafts) {
      final name = _basename(draft.path);
      final key = bundleIntentKey(name) ?? name;
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(draft);
    }

    return order.map((key) => groups[key]!).toList();
  }

  MigrationHeader? _mergeHeaders(List<File> drafts) {
    MigrationHeader? merged;
    for (final draft in drafts) {
      final header = MigrationHeader.parse(draft.readAsStringSync());
      if (!header.hasKind && header.touches.isEmpty && header.intent == null) {
        continue;
      }
      merged = merged == null ? header : merged.merge(header);
    }
    return merged;
  }

  PromoteDraftsResult promote(PromoteDraftsOptions options) {
    final planned = plan(options);
    if (options.dryRun) {
      return PromoteDraftsResult(planned: planned, written: const []);
    }

    final outputDir = migrationsDir(options.repoRoot);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final written = <File>[];
    for (final migration in planned) {
      final target = File('${outputDir.path}/${migration.outputFileName}');
      if (target.existsSync() && !options.force) {
        throw StateError(
          'Refusing to overwrite existing migration: ${target.path}. Use --force.',
        );
      }

      target.writeAsStringSync(migration.sql);
      written.add(target);
    }

    return PromoteDraftsResult(planned: planned, written: written);
  }

  int _compareDraftFiles(String leftPath, String rightPath) {
    final leftName = _basename(leftPath);
    final rightName = _basename(rightPath);

    final leftOrder = draftOrderNumber(leftName);
    final rightOrder = draftOrderNumber(rightName);

    if (leftOrder != null && rightOrder != null) {
      final byNumber = leftOrder.compareTo(rightOrder);
      if (byNumber != 0) {
        return byNumber;
      }
    }

    return leftName.compareTo(rightName);
  }

  int _parseMigrationId(String value) {
    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      throw FormatException(
        'Migration id must be YYYYMMDDxxx (11 digits): $value',
      );
    }
    return int.parse(value);
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
