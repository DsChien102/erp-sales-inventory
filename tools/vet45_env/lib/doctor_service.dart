import 'dart:io';

import 'key_resolver.dart';
import 'manifest.dart';
import 'project_ref.dart';
import 'secrets_loader.dart';
import 'supabase_cli.dart';

class DoctorReport {
  DoctorReport({required this.environmentId, required this.checks});

  final String environmentId;
  final List<DoctorCheck> checks;

  bool get ok => checks.every((c) => c.passed || c.skipped);

  void printReport() {
    stdout.writeln('Environment: $environmentId');
    for (final check in checks) {
      final icon = check.passed
          ? 'OK'
          : check.skipped
              ? 'SKIP'
              : 'FAIL';
      stdout.writeln(
        '  [$icon] ${check.name}${check.detail == null ? '' : ' — ${check.detail}'}',
      );
    }
  }
}

class DoctorCheck {
  DoctorCheck({
    required this.name,
    required this.passed,
    this.skipped = false,
    this.detail,
  });

  final String name;
  final bool passed;
  final bool skipped;
  final String? detail;
}

class DoctorService {
  DoctorService({
    required this.manifest,
    SupabaseCli? supabaseCli,
    this.skipNetwork = false,
  }) : _supabaseCli = supabaseCli ?? SupabaseCli(workdir: manifest.rootDir);

  final EnvManifest manifest;
  final SupabaseCli _supabaseCli;
  final bool skipNetwork;

  Future<DoctorReport> run(
    String environmentId, {
    String? targetId,
  }) async {
    final env = manifest.getEnvironment(environmentId);
    final checks = <DoctorCheck>[];

    checks.add(DoctorCheck(name: 'manifest entry', passed: true));

    final targetIds = _resolveTargetIds(targetId);
    final hasWritableTarget = targetIds.any(
      (id) => manifest.getTarget(id).writeEnvFile,
    );
    // Env-level secrets / link only matter for targets that write app .env files.
    if (hasWritableTarget) {
      _checkSupabaseLink(env, checks);
      await _checkSecretsSource(env, checks);
    }

    final targetOk = <String, bool>{};

    for (final id in targetIds) {
      final target = manifest.getTarget(id);
      final ok = target.writeEnvFile
          ? _checkWritableTarget(env, target, checks)
          : _checkSecretsOnlyTarget(env, target, checks);
      targetOk[id] = ok;
    }

    final erpOk = targetOk['erp'] == true;
    final workerOk = targetOk['worker'] == true;
    if (erpOk && workerOk) {
      _checkHostAlignment(env, checks);
    }

    if (!skipNetwork) {
      final pingUrl = _pingUrl(env, erpOk: erpOk, workerOk: workerOk);
      if (pingUrl != null && pingUrl.isNotEmpty) {
        final reachable = await _pingSupabase(pingUrl);
        checks.add(
          DoctorCheck(
            name: 'supabase http',
            passed: reachable,
            detail: pingUrl,
          ),
        );
      }
    } else {
      checks.add(
        DoctorCheck(
          name: 'supabase http',
          passed: true,
          skipped: true,
          detail: 'offline',
        ),
      );
    }

    return DoctorReport(environmentId: environmentId, checks: checks);
  }

  List<String> _resolveTargetIds(String? targetId) {
    if (targetId != null) {
      manifest.getTarget(targetId);
      return [targetId];
    }
    return manifest.targets.keys.toList()..sort();
  }

  void _checkSupabaseLink(
    EnvironmentDefinition env,
    List<DoctorCheck> checks,
  ) {
    if (!env.syncSupabaseLink) {
      checks.add(
        DoctorCheck(
          name: 'supabase cli link',
          passed: true,
          skipped: true,
          detail: 'disabled for ${env.id}',
        ),
      );
      return;
    }
    final targetRef = ProjectRefResolver.resolve(env);
    if (targetRef == null) {
      checks.add(
        DoctorCheck(
          name: 'supabase cli link',
          passed: true,
          skipped: true,
          detail: 'no hosted project ref configured',
        ),
      );
      return;
    }
    final currentRef = SupabaseCli.readLinkedProjectRef(manifest.rootDir);
    checks.add(
      DoctorCheck(
        name: 'supabase cli link',
        passed: currentRef == targetRef,
        detail: 'expected=$targetRef current=${currentRef ?? 'none'}',
      ),
    );
  }

  Future<void> _checkSecretsSource(
    EnvironmentDefinition env,
    List<DoctorCheck> checks,
  ) async {
    if (env.supabaseSource == 'secrets') {
      final exists = env.secretsFile.existsSync();
      if (exists) {
        checks.add(
          DoctorCheck(
            name: 'secrets file',
            passed: true,
            detail: env.secretsFile.path,
          ),
        );
      } else if (env.cliFallback) {
        try {
          await _supabaseCli.readStatusEnv();
          checks.add(
            DoctorCheck(
              name: 'secrets file',
              passed: true,
              skipped: true,
              detail: 'optional; using Supabase CLI fallback',
            ),
          );
        } on Object catch (e) {
          checks.add(
            DoctorCheck(
              name: 'secrets file',
              passed: false,
              detail: 'missing ${env.secretsFile.path}; CLI unavailable: $e',
            ),
          );
        }
      } else {
        checks.add(
          DoctorCheck(
            name: 'secrets file',
            passed: false,
            detail: 'missing ${env.secretsFile.path}',
          ),
        );
      }
      return;
    }

    try {
      await _supabaseCli.readStatusEnv();
      checks.add(DoctorCheck(name: 'supabase cli', passed: true));
    } on Object catch (e) {
      checks.add(
        DoctorCheck(
          name: 'supabase cli',
          passed: env.secretsFile.existsSync(),
          detail: env.secretsFile.existsSync()
              ? 'CLI unavailable; using secrets override'
              : '$e',
        ),
      );
    }
  }

  bool _checkWritableTarget(
    EnvironmentDefinition env,
    TargetDefinition target,
    List<DoctorCheck> checks,
  ) {
    final binding = env.binding(target.id);
    final envFile = binding?.envFile;
    if (envFile == null) {
      checks.add(
        DoctorCheck(
          name: '${target.id} binding',
          passed: false,
          detail: 'no envFile in environment ${env.id}',
        ),
      );
      return false;
    }

    final exists = envFile.existsSync();
    checks.add(
      DoctorCheck(
        name: '${target.id} env file',
        passed: exists,
        detail: envFile.path,
      ),
    );
    if (!exists) {
      return false;
    }

    final values = loadDotEnv(envFile);
    final missing = KeyResolver.missingRequired(
      target: target,
      values: values,
    );
    for (final key in target.keys.where((k) => k.required)) {
      final ok = !missing.contains(key.name);
      checks.add(
        DoctorCheck(
          name: '${target.id} ${key.name}',
          passed: ok,
        ),
      );
    }
    // fromManifest fields (e.g. APP_ENV) always required after sync.
    for (final key in target.keys.where((k) => k.fromManifest != null)) {
      final ok = (values[key.name] ?? '').trim().isNotEmpty;
      checks.add(
        DoctorCheck(
          name: '${target.id} ${key.name}',
          passed: ok,
        ),
      );
    }
    return missing.isEmpty;
  }

  bool _checkSecretsOnlyTarget(
    EnvironmentDefinition env,
    TargetDefinition target,
    List<DoctorCheck> checks,
  ) {
    final secretsFile = target.secretsSource(env);
    final exists = secretsFile.existsSync();
    checks.add(
      DoctorCheck(
        name: '${target.id} secrets file',
        passed: exists,
        detail: secretsFile.path,
      ),
    );
    if (!exists) {
      return false;
    }

    final values = loadDotEnv(secretsFile);
    final missing = KeyResolver.missingRequired(
      target: target,
      values: values,
    );
    for (final key in target.keys.where((k) => k.required)) {
      checks.add(
        DoctorCheck(
          name: '${target.id} ${key.name}',
          passed: !missing.contains(key.name),
        ),
      );
    }
    return missing.isEmpty;
  }

  void _checkHostAlignment(
    EnvironmentDefinition env,
    List<DoctorCheck> checks,
  ) {
    final erpFile = env.erp?.envFile;
    final workerFile = env.worker?.envFile;
    if (erpFile == null ||
        workerFile == null ||
        !erpFile.existsSync() ||
        !workerFile.existsSync()) {
      return;
    }
    final erp = loadDotEnv(erpFile);
    final worker = loadDotEnv(workerFile);
    final erpUrl = erp['SUPABASE_CONNECTION_URL'] ?? erp['SUPABASE_URL'] ?? '';
    final workerUrl = worker['SUPABASE_URL'] ?? '';
    final sameHost = _normalizeHost(erpUrl) == _normalizeHost(workerUrl);
    checks.add(
      DoctorCheck(
        name: 'erp/worker supabase host',
        passed: sameHost && erpUrl.isNotEmpty,
        detail: 'erp=$erpUrl worker=$workerUrl',
      ),
    );
  }

  String? _pingUrl(
    EnvironmentDefinition env, {
    required bool erpOk,
    required bool workerOk,
  }) {
    if (workerOk) {
      final file = env.worker?.envFile;
      if (file != null && file.existsSync()) {
        return loadDotEnv(file)['SUPABASE_URL'];
      }
    }
    if (erpOk) {
      final file = env.erp?.envFile;
      if (file != null && file.existsSync()) {
        final erp = loadDotEnv(file);
        return erp['SUPABASE_CONNECTION_URL'] ?? erp['SUPABASE_URL'];
      }
    }
    return null;
  }

  String _normalizeHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }
    return '${uri.scheme}://${uri.host}:${uri.hasPort ? uri.port : ''}';
  }

  Future<bool> _pingSupabase(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri.replace(path: '/rest/v1/'));
      final response = await request.close();
      final ok = response.statusCode >= 200 && response.statusCode < 500;
      client.close(force: true);
      return ok;
    } on Object {
      return false;
    }
  }
}
