import 'dart:io';

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
      stdout.writeln('  [$icon] ${check.name}${check.detail == null ? '' : ' — ${check.detail}'}');
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

  Future<DoctorReport> run(String environmentId) async {
    final env = manifest.getEnvironment(environmentId);
    final checks = <DoctorCheck>[];

    checks.add(DoctorCheck(name: 'manifest entry', passed: true));

    if (env.syncSupabaseLink) {
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
      } else {
        final currentRef = SupabaseCli.readLinkedProjectRef(manifest.rootDir);
        checks.add(
          DoctorCheck(
            name: 'supabase cli link',
            passed: currentRef == targetRef,
            detail: 'expected=$targetRef current=${currentRef ?? 'none'}',
          ),
        );
      }
    } else {
      checks.add(
        DoctorCheck(
          name: 'supabase cli link',
          passed: true,
          skipped: true,
          detail: 'disabled for ${env.id}',
        ),
      );
    }

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
              detail:
                  'missing ${env.secretsFile.path}; CLI unavailable: $e',
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
    } else {
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

    final erpExists = env.erp.envFile.existsSync();
    checks.add(
      DoctorCheck(
        name: 'erp env file',
        passed: erpExists,
        detail: env.erp.envFile.path,
      ),
    );

    final workerExists = env.worker.envFile.existsSync();
    checks.add(
      DoctorCheck(
        name: 'worker env file',
        passed: workerExists,
        detail: env.worker.envFile.path,
      ),
    );

    if (erpExists && workerExists) {
      final erp = loadDotEnv(env.erp.envFile);
      final worker = loadDotEnv(env.worker.envFile);
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

      for (final key in ['SUPABASE_ANON_KEY']) {
        final ok = (erp[key] ?? '').trim().isNotEmpty;
        checks.add(DoctorCheck(name: 'erp $key', passed: ok));
      }
      for (final key in ['SUPABASE_SERVICE_ROLE_KEY', 'WORKER_TICK_SECRET']) {
        final ok = (worker[key] ?? '').trim().isNotEmpty;
        checks.add(DoctorCheck(name: 'worker $key', passed: ok));
      }

      if (!skipNetwork && workerUrl.isNotEmpty) {
        final reachable = await _pingSupabase(workerUrl);
        checks.add(
          DoctorCheck(
            name: 'supabase http',
            passed: reachable,
            detail: workerUrl,
          ),
        );
      } else if (skipNetwork) {
        checks.add(
          DoctorCheck(name: 'supabase http', passed: true, skipped: true, detail: 'offline'),
        );
      }
    }

    return DoctorReport(environmentId: environmentId, checks: checks);
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
