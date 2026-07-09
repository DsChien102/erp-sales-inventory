import 'dart:io';

import 'doctor_service.dart';
import 'link_service.dart';
import 'manifest.dart';
import 'process_runner.dart';
import 'profile_registry.dart';
import 'resolve_service.dart';
import 'secrets_loader.dart';
import 'sync_service.dart';

/// Cross-platform orchestration for `vet45_env run` (replaces bash wrapper).
class RunService {
  RunService({
    required this.manifest,
    required this.syncService,
    required this.linkService,
    required this.doctorService,
    ProcessRunner? processRunner,
  }) : _process = processRunner ?? IoProcessRunner();

  final EnvManifest manifest;
  final SyncService syncService;
  final SupabaseLinkService linkService;
  final DoctorService doctorService;
  final ProcessRunner _process;

  Directory get _root => manifest.rootDir;

  Future<void> useProfile(String profileId) async {
    manifest.profiles.getProfile(profileId);
    final state = readActiveState(
      manifest.rootDir,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    writeActiveState(
      manifest.rootDir,
      ActiveState(profileId: profileId, environmentId: state.environmentId),
    );
    stdout.writeln('Active profile: $profileId');
  }

  Future<void> useAndSync(
    String environmentId, {
    String? profileId,
    String? targetId,
    bool skipLink = false,
  }) async {
    final ctx = _writeEnvironment(environmentId, profileId: profileId);
    if (!skipLink) {
      (await linkService.ensureLinked(ctx)).printSummary();
    }
    stdout.writeln(
      'Active: profile=${ctx.profileId} environment=${ctx.environmentId}',
    );
    await _syncOrExit(ctx, targetId: targetId);
  }

  Future<int> useSyncRun(
    String environmentId,
    String target,
    String action, {
    String? profileId,
    List<String> extraArgs = const [],
    bool skipLink = false,
  }) async {
    await useAndSync(
      environmentId,
      profileId: profileId,
      targetId: target,
      skipLink: skipLink,
    );
    return run(
      target,
      action,
      extraArgs: extraArgs,
      profileId: profileId,
      environmentId: environmentId,
      skipSync: true,
    );
  }

  Future<int> run(
    String target,
    String action, {
    List<String> extraArgs = const [],
    String? profileId,
    String? environmentId,
    bool skipSync = false,
  }) async {
    final ctx = manifest.context(
      profileId: profileId,
      environmentId: environmentId,
    );

    if (!skipSync) {
      await _syncOrExit(ctx, targetId: target);
    }
    final resolved = ResolvedRunContext.fromWorkspace(ctx, manifest);

    switch (target) {
      case 'erp':
        return _runErp(resolved, action, extraArgs);
      case 'worker':
        return _runWorker(resolved, action, extraArgs);
      default:
        stderr.writeln('Unknown run target: $target');
        return 64;
    }
  }

  WorkspaceContext _writeEnvironment(
    String environmentId, {
    String? profileId,
  }) {
    manifest.getEnvironment(environmentId);
    final state = readActiveState(
      manifest.rootDir,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    final next = ActiveState(
      profileId: profileId ?? state.profileId,
      environmentId: environmentId,
    );
    writeActiveState(manifest.rootDir, next);
    return manifest.context(profileId: next.profileId, environmentId: environmentId);
  }

  Future<void> _syncOrExit(WorkspaceContext ctx, {String? targetId}) async {
    final result = await syncService.sync(ctx, targetId: targetId);
    if (!result.ok) {
      for (final entry in result.failures.entries) {
        stderr.writeln('sync failed for ${entry.key}: ${entry.value}');
      }
      exit(1);
    }
  }

  Future<int> _runErp(
    ResolvedRunContext ctx,
    String action,
    List<String> extraArgs,
  ) async {
    final flavor = ctx.erpFlavor;
    final envBasename = ctx.erpEnvBasename;
    final erpDir = '${_root.path}/apps/erp';

    if (flavor == null || envBasename == null || ctx.erpEnvFile == null) {
      stderr.writeln(
        'ERP binding missing for profile ${ctx.profileId} / ${ctx.environmentId}',
      );
      return 1;
    }
    if (!File(ctx.erpEnvFile!).existsSync()) {
      stderr.writeln('Missing ERP env file: ${ctx.erpEnvFile}');
      stderr.writeln('Run: melos run env:sync -- --target erp');
      return 1;
    }

    switch (action) {
      case 'debug':
        return _process.run(
          'flutter',
          [
            'run',
            '--flavor',
            flavor,
            '--dart-define-from-file=$envBasename',
            ...extraArgs,
          ],
          workingDirectory: erpDir,
        );
      case 'debug:web':
        return _process.run(
          'flutter',
          [
            'run',
            '-d',
            'chrome',
            '--flavor',
            flavor,
            '--dart-define-from-file=$envBasename',
            ...extraArgs,
          ],
          workingDirectory: erpDir,
        );
      case 'debug:ios':
        if (!Platform.isMacOS) {
          stderr.writeln('debug:ios requires macOS with Xcode.');
          return 64;
        }
        return _process.run(
          'flutter',
          [
            'run',
            '-d',
            'ios',
            '--flavor',
            flavor,
            '--dart-define-from-file=$envBasename',
            ...extraArgs,
          ],
          workingDirectory: erpDir,
        );
      case 'build-ios':
        return _runMacOsShellScript(
          '${_root.path}/apps/erp/scripts/build_ios.sh',
          ['--env', ctx.environmentId, ...extraArgs],
        );
      case 'deploy-ios':
        _requireIosDeployEnv(ctx.environmentId);
        final doctor = await doctorService.run(
          manifest.context(environmentId: ctx.environmentId, profileId: ctx.profileId),
          targetId: 'deploy',
        );
        if (!doctor.ok) {
          doctor.printReport();
          return 1;
        }
        final buildCode = await _runMacOsShellScript(
          '${_root.path}/apps/erp/scripts/build_ios.sh',
          ['--env', ctx.environmentId],
        );
        if (buildCode != 0) {
          return buildCode;
        }
        return _runMacOsShellScript(
          '${_root.path}/apps/erp/deploy-ios.sh',
          ['--env', ctx.environmentId, ...extraArgs],
        );
      default:
        stderr.writeln('Unknown erp action: $action');
        return 64;
    }
  }

  Future<int> _runWorker(
    ResolvedRunContext ctx,
    String action,
    List<String> extraArgs,
  ) async {
    final workerEnvFile = ctx.workerEnvFile;
    if (workerEnvFile == null) {
      stderr.writeln(
        'Worker binding missing for profile ${ctx.profileId} / ${ctx.environmentId}',
      );
      return 1;
    }
    if (!File(workerEnvFile).existsSync()) {
      stderr.writeln('Missing worker env file: $workerEnvFile');
      stderr.writeln('Run: melos run env:sync -- --target worker');
      return 1;
    }

    switch (action) {
      case 'serve':
      case 'once':
        await _checkLocalSupabaseReachable(workerEnvFile);
        return _runWorkerDart(workerEnvFile, '--$action');
      case 'docker':
        return _runWorkerDocker(workerEnvFile, ctx.workerDockerSupabaseUrl);
      case 'deploy':
        _requireRailwayDeployEnv(ctx);
        return _runShellScript(
          '${_root.path}/apps/messaging_worker/scripts/deploy.sh',
          ['--env', ctx.railwayEnvironment!, ...extraArgs],
        );
      default:
        stderr.writeln('Unknown worker action: $action');
        return 64;
    }
  }

  Future<int> _runWorkerDart(String envFilePath, String modeFlag) async {
    final dotenv = loadDotEnv(File(envFilePath));
    return _process.run(
      'dart',
      ['run', 'bin/worker.dart', modeFlag],
      workingDirectory: '${_root.path}/apps/messaging_worker',
      environment: {...Platform.environment, ...dotenv},
    );
  }

  Future<int> _runWorkerDocker(
    String envFilePath,
    String? dockerSupabaseUrl,
  ) async {
    final environment = <String, String>{
      ...Platform.environment,
      'WORKER_ENV_FILE': envFilePath,
    };
    if (dockerSupabaseUrl != null && dockerSupabaseUrl.isNotEmpty) {
      environment['WORKER_SUPABASE_URL'] = dockerSupabaseUrl;
    }
    return _process.run(
      'docker',
      ['compose', 'up', '--build', 'messaging-worker'],
      workingDirectory: _root.path,
      environment: environment,
    );
  }

  Future<void> _checkLocalSupabaseReachable(String envFilePath) async {
    final values = loadDotEnv(File(envFilePath));
    final url = values['SUPABASE_URL']?.trim() ?? '';
    if (url.isEmpty) {
      return;
    }
    if (!url.contains('127.0.0.1') && !url.contains('localhost')) {
      return;
    }
    final reachable = await _pingSupabase(url);
    if (!reachable) {
      stderr.writeln('ERROR: Supabase not reachable at $url');
      stderr.writeln(
        '       Run: supabase start && melos run env:sync -- --target worker',
      );
      exit(1);
    }
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

  void _requireIosDeployEnv(String environmentId) {
    if (environmentId != 'staging' && environmentId != 'production') {
      stderr.writeln(
        'iOS build/deploy requires staging or production (current: $environmentId)',
      );
      stderr.writeln('Run: melos run env:use:staging');
      exit(1);
    }
    if (!Platform.isMacOS) {
      stderr.writeln('iOS build/deploy requires macOS with Xcode.');
      exit(64);
    }
  }

  void _requireRailwayDeployEnv(ResolvedRunContext ctx) {
    final railway = ctx.railwayEnvironment;
    if (railway == null || railway.isEmpty) {
      stderr.writeln(
        'Worker deploy requires Railway target (active: ${ctx.environmentId})',
      );
      stderr.writeln('Run: melos run env:use:staging');
      exit(1);
    }
  }

  Future<int> _runMacOsShellScript(String scriptPath, List<String> args) async {
    if (!Platform.isMacOS) {
      stderr.writeln('This action requires macOS: $scriptPath');
      return 64;
    }
    return _runShellScript(scriptPath, args);
  }

  Future<int> _runShellScript(String scriptPath, List<String> args) async {
    if (Platform.isWindows) {
      return _process.run(
        'bash',
        [scriptPath, ...args],
        workingDirectory: _root.path,
      );
    }
    return _process.run(scriptPath, args, workingDirectory: _root.path);
  }
}
