import 'dart:convert';
import 'dart:io';

import 'apply_dev_service.dart';

/// Reads active profile + environment and resolves a Supabase project ref.
ApplyDevTarget resolveApplyDevTarget(Directory repoRoot) {
  final stateFile = File('${repoRoot.path}/.vet45/state.json');
  if (!stateFile.existsSync()) {
    throw ApplyDevException(
      'No active profile (.vet45/state.json missing). Run: vet45 init <profileId>',
    );
  }

  late final Map<String, dynamic> json;
  try {
    json = jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
  } on Object {
    throw const ApplyDevException('Corrupt .vet45/state.json');
  }

  final profileId = (json['profile'] as String?)?.trim() ?? '';
  final environmentId = (json['environment'] as String?)?.trim() ?? '';
  if (profileId.isEmpty || environmentId.isEmpty) {
    throw const ApplyDevException(
      'Active profile/environment missing in .vet45/state.json. '
      'Run: vet45 switch <profile> <env>',
    );
  }

  final secretsFile =
      File('${repoRoot.path}/.vet45/profiles/$profileId/$environmentId.env');
  if (!secretsFile.existsSync()) {
    throw ApplyDevException(
      'Missing secrets file: ${secretsFile.path}',
    );
  }

  final secrets = _loadDotEnv(secretsFile);
  final projectRef = _projectRefFromSecrets(secrets);
  if (projectRef == null || projectRef.isEmpty) {
    throw ApplyDevException(
      'Could not resolve SUPABASE_PROJECT_REF from '
      '.vet45/profiles/$profileId/$environmentId.env '
      '(set SUPABASE_PROJECT_REF or SUPABASE_URL).',
    );
  }

  return ApplyDevTarget(
    profileId: profileId,
    environmentId: environmentId,
    projectRef: projectRef,
  );
}

/// Connection URI for `psql` / Postgres drivers.
String? resolveDatabaseUrl(Directory repoRoot, ApplyDevTarget target) {
  final secretsFile = File(
    '${repoRoot.path}/.vet45/profiles/${target.profileId}/${target.environmentId}.env',
  );
  if (!secretsFile.existsSync()) {
    return null;
  }
  final secrets = _loadDotEnv(secretsFile);
  for (final key in const [
    'DATABASE_URL',
    'SUPABASE_DB_URL',
    'SUPABASE_DATABASE_URL',
  ]) {
    final value = secrets[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _projectRefFromSecrets(Map<String, String> secrets) {
  final explicit = secrets['SUPABASE_PROJECT_REF']?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  final url = secrets['SUPABASE_URL']?.trim() ?? '';
  final match = RegExp(r'https://([a-z0-9-]+)\.supabase\.co', caseSensitive: false)
      .firstMatch(url);
  return match?.group(1);
}

Map<String, String> _loadDotEnv(File file) {
  final result = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final eq = trimmed.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}

/// Runs SQL via `psql` using [databaseUrl].
class PsqlSqlExecutor implements SqlExecutor {
  PsqlSqlExecutor(this.databaseUrl);

  final String databaseUrl;

  @override
  Future<void> execute(String sql) async {
    final result = await Process.run(
      'psql',
      [databaseUrl, '-v', 'ON_ERROR_STOP=1', '-c', sql],
    );
    if (result.exitCode != 0) {
      throw ApplyDevException(
        'psql failed (${result.exitCode}): ${result.stderr}',
      );
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(String sql) async {
    final result = await Process.run(
      'psql',
      [
        databaseUrl,
        '-v',
        'ON_ERROR_STOP=1',
        '-A',
        '-F',
        '\t',
        '-P',
        'footer=off',
        '-c',
        sql,
      ],
    );
    if (result.exitCode != 0) {
      throw ApplyDevException(
        'psql query failed (${result.exitCode}): ${result.stderr}',
      );
    }
    final stdout = (result.stdout as String).trimRight();
    if (stdout.trim().isEmpty) {
      return const [];
    }
    final lines = stdout
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const [];
    }
    final headers = lines.first.split('\t');
    return [
      for (final line in lines.skip(1))
        () {
          final parts = line.split('\t');
          return <String, Object?>{
            for (var index = 0; index < headers.length; index++)
              headers[index]: index < parts.length ? parts[index] : '',
          };
        }(),
    ];
  }
}
