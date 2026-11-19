import 'dart:io';

import 'sql_object_render.dart';
import 'sql_source_discovery.dart';

/// Executes SQL against a Postgres database (real or fake).
abstract class SqlExecutor {
  /// Runs a statement that may return rows.
  Future<List<Map<String, Object?>>> query(String sql);

  /// Runs a statement with no result set requirement.
  Future<void> execute(String sql);
}

/// Target resolved from the active c45 profile / environment.
class ApplyDevTarget {
  const ApplyDevTarget({
    required this.profileId,
    required this.environmentId,
    required this.projectRef,
  });

  final String profileId;
  final String environmentId;

  /// Supabase project ref shown at confirm time.
  final String projectRef;
}

class ApplyDevOptions {
  const ApplyDevOptions({
    required this.repoRoot,
    required this.target,
    this.confirmed = false,
  });

  final Directory repoRoot;
  final ApplyDevTarget target;

  /// When false and there is work to apply, throws [ApplyDevConfirmationRequired].
  final bool confirmed;
}

class ApplyDevObject {
  const ApplyDevObject({
    required this.qualifiedName,
    required this.hash,
    required this.sql,
  });

  final String qualifiedName;
  final String hash;

  /// SQL to apply (declarative source, with drop wrappers for trigger/policy).
  final String sql;
}

class ApplyDevResult {
  const ApplyDevResult({
    required this.applied,
    required this.skipped,
  });

  final List<String> applied;
  final List<String> skipped;
}

/// Thrown when the operator must confirm project ref + object list.
class ApplyDevConfirmationRequired implements Exception {
  const ApplyDevConfirmationRequired({
    required this.target,
    required this.objects,
  });

  final ApplyDevTarget target;
  final List<ApplyDevObject> objects;

  @override
  String toString() {
    final names = objects.map((object) => object.qualifiedName).join(', ');
    return 'Confirm schema:apply-dev to project ${target.projectRef} '
        '(${target.profileId}/${target.environmentId}) for: $names';
  }
}

class ApplyDevException implements Exception {
  const ApplyDevException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Environments allowed for `schema:apply-dev`.
const applyDevAllowlist = {'development', 'local', 'sandbox', 'dev'};

/// Environments that are always refused.
const applyDevDenylist = {'staging', 'production', 'prod'};

const applyDevLogSchema = 'c45_dev';
const applyDevLogTable = '$applyDevLogSchema.schema_apply_log';

/// Applies declarative SQL sources that differ from the per-DB apply log.
///
/// Does **not** run draft pre/post regions. Tracks hashes in
/// `c45_dev.schema_apply_log` on the target database.
class ApplyDevService {
  ApplyDevService({
    required SqlExecutor executor,
    SqlSourceDiscovery? discovery,
  })  : _executor = executor,
        _discovery = discovery ?? SqlSourceDiscovery();

  final SqlExecutor _executor;
  final SqlSourceDiscovery _discovery;

  /// Validates [target.environmentId] against allow/deny lists.
  void assertEnvironmentAllowed(String environmentId) {
    final env = environmentId.trim().toLowerCase();
    if (applyDevDenylist.contains(env)) {
      throw ApplyDevException(
        'schema:apply-dev refuses environment "$environmentId" '
        '(staging/prod are never allowed).',
      );
    }
    if (!applyDevAllowlist.contains(env)) {
      throw ApplyDevException(
        'schema:apply-dev only runs on allowlisted envs '
        '(${applyDevAllowlist.join(", ")}); got "$environmentId".',
      );
    }
  }

  Future<ApplyDevResult> apply(ApplyDevOptions options) async {
    assertEnvironmentAllowed(options.target.environmentId);

    final sources = _discovery.discover(options.repoRoot);
    await _ensureApplyLog();
    final appliedHashes = await _loadAppliedHashes();

    final pending = <ApplyDevObject>[];
    final skipped = <String>[];
    for (final source in sources) {
      final previous = appliedHashes[source.qualifiedName];
      if (previous == source.hash) {
        skipped.add(source.qualifiedName);
        continue;
      }
      pending.add(
        ApplyDevObject(
          qualifiedName: source.qualifiedName,
          hash: source.hash,
          sql: renderDeclarativeSource(source),
        ),
      );
    }

    if (pending.isEmpty) {
      return ApplyDevResult(applied: const [], skipped: skipped);
    }

    if (!options.confirmed) {
      throw ApplyDevConfirmationRequired(
        target: options.target,
        objects: pending,
      );
    }

    final applied = <String>[];
    for (final object in pending) {
      await _executor.execute(object.sql);
      await _executor.execute(
        'insert into $applyDevLogTable (object_name, hash, applied_at) '
        "values ('${_escape(object.qualifiedName)}', '${_escape(object.hash)}', now()) "
        'on conflict (object_name) do update set '
        "hash = excluded.hash, applied_at = excluded.applied_at;",
      );
      applied.add(object.qualifiedName);
    }

    return ApplyDevResult(applied: applied, skipped: skipped);
  }

  Future<void> _ensureApplyLog() async {
    await _executor.execute(
      'create schema if not exists $applyDevLogSchema;',
    );
    await _executor.execute(
      'create table if not exists $applyDevLogTable ('
      '  object_name text primary key,'
      '  hash text not null,'
      '  applied_at timestamptz not null default now()'
      ');',
    );
  }

  Future<Map<String, String>> _loadAppliedHashes() async {
    final rows = await _executor.query(
      'select object_name, hash from $applyDevLogTable;',
    );
    return {
      for (final row in rows)
        row['object_name']!.toString(): row['hash']!.toString(),
    };
  }

  String _escape(String value) => value.replaceAll("'", "''");
}
