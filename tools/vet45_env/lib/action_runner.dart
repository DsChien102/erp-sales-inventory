import 'dart:io';

import 'action_spec.dart';
import 'doctor_service.dart';
import 'manifest.dart';
import 'process_runner.dart';
import 'profile_registry.dart';
import 'secrets_loader.dart';
import 'target_manifest.dart';

/// Executes declarative actions from target manifests.
class ActionRunner {
  ActionRunner({
    required this.manifest,
    required this.doctorService,
    ProcessRunner? processRunner,
  }) : _process = processRunner ?? IoProcessRunner();

  final EnvManifest manifest;
  final DoctorService doctorService;
  final ProcessRunner _process;

  Future<int> run({
    required WorkspaceContext ctx,
    required String targetId,
    required String actionId,
    List<String> extraArgs = const [],
  }) async {
    final target = manifest.getTarget(targetId);
    final spec = target.actions[actionId];
    if (spec == null) {
      stderr.writeln('Unknown action "$actionId" for target "$targetId"');
      stderr.writeln(
        'Available: ${target.actions.keys.join(', ')}',
      );
      return 64;
    }

    if (!_platformAllowed(spec.platforms)) {
      stderr.writeln(
        'Action "$actionId" requires platform: ${spec.platforms.join(', ')}',
      );
      return 64;
    }

    if (spec.requireEnvironments.isNotEmpty &&
        !spec.requireEnvironments.contains(ctx.environment.id)) {
      stderr.writeln(
        'Action "$actionId" requires environment: '
        '${spec.requireEnvironments.join(' or ')} '
        '(current: ${ctx.environment.id})',
      );
      stderr.writeln('Run: vet45 switch ${ctx.profileId} <env>');
      return 1;
    }

    if (spec.requireRailwayEnvironment) {
      final railway = ctx.environment.railwayEnvironment;
      if (railway == null || railway.isEmpty) {
        stderr.writeln(
          'Action "$actionId" requires Railway environment '
          '(active: ${ctx.environment.id})',
        );
        stderr.writeln('Run: vet45 switch ${ctx.profileId} staging');
        return 1;
      }
    }

    final binding = ctx.environment.binding(targetId);
    final envFile = binding?.envFile;

    if (spec.requireEnvFile &&
        (envFile == null || !envFile.existsSync())) {
      stderr.writeln(
        'Missing env file for target "$targetId" '
        '(profile ${ctx.profileId} / ${ctx.environment.id})',
      );
      if (envFile != null) {
        stderr.writeln('Expected: ${envFile.path}');
      }
      stderr.writeln('Run: vet45 sync --target $targetId');
      return 1;
    }

    if (spec.requireDoctorTargets.isNotEmpty) {
      for (final doctorTarget in spec.requireDoctorTargets) {
        final report = await doctorService.run(
          ctx,
          targetId: doctorTarget,
        );
        if (!report.ok) {
          report.printReport();
          return 1;
        }
      }
    }

    for (final pre in spec.preActions) {
      final code = await run(
        ctx: ctx,
        targetId: targetId,
        actionId: pre,
      );
      if (code != 0) {
        return code;
      }
    }

    if (spec.localSupabaseCheck && envFile != null) {
      await _checkLocalSupabaseReachable(envFile);
    }

    final template = ActionTemplate(
      buildActionTemplateVars(
        profileId: ctx.profileId,
        environmentId: ctx.environment.id,
        workspaceRoot: manifest.rootDir.path,
        secretsFile: ctx.secretsFile.path,
        railwayEnvironment: ctx.environment.railwayEnvironment,
        envFile: envFile?.path,
        bindingFields: binding?.fields ?? const {},
      ),
    );

    final cwd = _resolveCwd(
      template.expand(spec.cwd),
      target.manifestDir ?? manifest.rootDir,
    );

    final command = template.expand(spec.command);
    final args = [
      ...template.expandAll(spec.args),
      ...extraArgs,
    ];

    var environment = Map<String, String>.from(Platform.environment);
    if (spec.env.isNotEmpty) {
      for (final entry in template.expandEnv(spec.env).entries) {
        if (entry.value.isNotEmpty) {
          environment[entry.key] = entry.value;
        }
      }
    }
    if (spec.passEnvFile && envFile != null) {
      environment.addAll(loadDotEnv(envFile));
    }

    return _runCommand(
      command,
      args,
      workingDirectory: cwd,
      environment: environment,
    );
  }

  bool _platformAllowed(List<String> platforms) {
    if (platforms.isEmpty) {
      return true;
    }
    if (platforms.contains('macos') && Platform.isMacOS) {
      return true;
    }
    if (platforms.contains('linux') && Platform.isLinux) {
      return true;
    }
    if (platforms.contains('windows') && Platform.isWindows) {
      return true;
    }
    return false;
  }

  String _resolveCwd(String cwd, Directory manifestDir) {
    if (cwd == '.' || cwd.isEmpty) {
      return manifestDir.path;
    }
    if (Path.isAbsolute(cwd)) {
      return cwd;
    }
    return TargetManifest.normalizePath('${manifestDir.path}/$cwd');
  }

  Future<int> _runCommand(
    String command,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (command.startsWith('./') || command.startsWith('.\\')) {
      final scriptPath = TargetManifest.normalizePath(
        '$workingDirectory/${command.substring(2)}',
      );
      if (Platform.isWindows) {
        return _process.run(
          'bash',
          [scriptPath, ...args],
          workingDirectory: workingDirectory,
          environment: environment,
        );
      }
      return _process.run(
        scriptPath,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    }
    return _process.run(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  Future<void> _checkLocalSupabaseReachable(File envFile) async {
    final values = loadDotEnv(envFile);
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
      stderr.writeln('       Run: supabase start && vet45 sync');
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
}

/// Minimal path helpers without importing `path` package.
abstract final class Path {
  static bool isAbsolute(String p) {
    if (p.startsWith('/')) {
      return true;
    }
    return p.length >= 3 && p[1] == ':' && (p[2] == '/' || p[2] == '\\');
  }
}
