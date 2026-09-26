import 'dart:io';

import 'schema_lock.dart';
import 'sql_source_discovery.dart';

/// Diff between declarative sources on disk and `supabase/schema.lock.yaml`.
class SchemaLockSyncDiff {
  const SchemaLockSyncDiff({
    required this.added,
    required this.changed,
    required this.removed,
  });

  /// Objects present in sources but missing from the lock.
  final List<String> added;

  /// Objects whose source hash differs from the lock.
  final List<String> changed;

  /// Objects in the lock whose source file is gone.
  final List<String> removed;

  bool get isSynced =>
      added.isEmpty && changed.isEmpty && removed.isEmpty;

  List<String> get all => [...added, ...changed, ...removed]..sort();
}

/// Compares discovered declarative sources to [SchemaLock].
class SchemaLockSyncChecker {
  SchemaLockSyncChecker({SqlSourceDiscovery? discovery})
      : _discovery = discovery ?? SqlSourceDiscovery();

  final SqlSourceDiscovery _discovery;

  SchemaLockSyncDiff check({
    required Directory repoRoot,
    SchemaLock? lock,
  }) {
    final sources = _discovery.discover(repoRoot);
    final loaded =
        lock ?? SchemaLock.load(File('${repoRoot.path}/$schemaLockRelativePath'));

    final sourceByName = {
      for (final source in sources) source.qualifiedName: source,
    };

    final added = <String>[];
    final changed = <String>[];
    for (final source in sources) {
      final entry = loaded.entries[source.qualifiedName];
      if (entry == null) {
        added.add(source.qualifiedName);
      } else if (entry.hash != source.hash) {
        changed.add(source.qualifiedName);
      }
    }

    final removed = <String>[
      for (final name in loaded.entries.keys)
        if (!sourceByName.containsKey(name)) name,
    ]..sort();

    added.sort();
    changed.sort();
    return SchemaLockSyncDiff(
      added: added,
      changed: changed,
      removed: removed,
    );
  }
}

/// Branches where an unsynced lock must fail CI (promote/release).
bool isPromoteOrReleaseBranch(String? branch) {
  if (branch == null || branch.isEmpty) {
    return false;
  }
  final name = branch.trim();
  return name == 'main' ||
      name == 'master' ||
      name.startsWith('release/') ||
      name.startsWith('promote/');
}

/// Resolves the current git branch from env (CI) or `git rev-parse`.
String? detectCurrentBranch({
  Map<String, String>? environment,
  String Function()? gitBranch,
}) {
  final env = environment ?? Platform.environment;
  for (final key in const [
    'CI_COMMIT_REF_NAME',
    'CI_COMMIT_BRANCH',
    'GITHUB_REF_NAME',
    'VET45_LOCK_SYNC_BRANCH',
  ]) {
    final value = env[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  final githubRef = env['GITHUB_REF']?.trim();
  if (githubRef != null && githubRef.startsWith('refs/heads/')) {
    return githubRef.substring('refs/heads/'.length);
  }

  if (gitBranch != null) {
    return gitBranch();
  }

  try {
    final result = Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      final name = (result.stdout as String).trim();
      if (name.isNotEmpty && name != 'HEAD') {
        return name;
      }
    }
  } on Object {
    // Best-effort; callers treat null as slice (warn-only).
  }
  return null;
}
