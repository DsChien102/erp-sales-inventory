import 'dart:io';

import 'action_spec.dart';
import 'doctor_service.dart';
import 'manifest.dart';
import 'process_runner.dart';
import 'profile_registry.dart';
import 'secrets_loader.dart';
import 'target_manifest.dart';

/// Resolved command ready to execute (CLI ProcessRunner or TUI PTY).
class ActionLaunchPlan {
  ActionLaunchPlan({
    required this.command,
    required this.args,
    required this.workingDirectory,
    required this.environment,
    required this.targetId,
    required this.actionId,
  });

  final String command;
  final List<String> args;
  final String workingDirectory;
  final Map<String, String> environment;
  final String targetId;
  final String actionId;

  String get label => '$targetId/$actionId';
}

/// Thrown when an action cannot be resolved or a preAction fails.
class ActionLaunchException implements Exception {
  ActionLaunchException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}

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

  /// Validates + expands templates; runs [preActions] via ProcessRunner first.
  Future<ActionLaunchPlan> resolveLaunch({
    required WorkspaceContext ctx,
    required String targetId,
    required String actionId,
    List<String> extraArgs = const [],
    bool runPreActions = true,
  }) async {
    final target = manifest.getTarget(targetId);
    final spec = target.actions[actionId];
    if (spec == null) {
      throw ActionLaunchException(
        'Unknown action "$actionId" for target "$targetId"\n'
        'Available: ${target.actions.keys.join(', ')}',
        exitCode: 64,
      );
    }

    final disabled = disabledReason(
      spec: spec,
      ctx: ctx,
      targetId: targetId,
    );
    if (disabled != null) {
      final exitCode = !isPlatformAllowed(spec.platforms) ? 64 : 1;
      throw ActionLaunchException(disabled, exitCode: exitCode);
    }

    final binding = ctx.environment.binding(targetId);
    final envFile = binding?.envFile;

    if (spec.requireDoctorTargets.isNotEmpty) {
      for (final doctorTarget in spec.requireDoctorTargets) {
        final report = await doctorService.run(
          ctx,
          targetId: doctorTarget,
        );
        if (!report.ok) {
          final detail = report.checks
              .where((c) => !c.passed && !c.skipped)
              .map((c) => c.name)
              .join(', ');
          throw ActionLaunchException(
            'Doctor failed for target "$doctorTarget"'
            '${detail.isEmpty ? '' : ': $detail'}',
          );
        }
      }
    }

    if (runPreActions) {
      for (final pre in spec.preActions) {
        final code = await run(
          ctx: ctx,
          targetId: targetId,
          actionId: pre,
        );
        if (code != 0) {
          throw ActionLaunchException(
            'preAction "$pre" failed with exit code $code',
            exitCode: code,
          );
        }
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

    var command = template.expand(spec.command);
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

    // Normalize ./script for PTY / Process.start
    if (command.startsWith('./') || command.startsWith('.\\')) {
      final scriptPath = TargetManifest.normalizePath(
        '$cwd/${command.substring(2)}',
      );
      if (Platform.isWindows) {
        return ActionLaunchPlan(
          command: 'bash',
          args: [scriptPath, ...args],
          workingDirectory: cwd,
          environment: environment,
          targetId: targetId,
          actionId: actionId,
        );
      }
      command = scriptPath;
    }

    return ActionLaunchPlan(
      command: command,
      args: args,
      workingDirectory: cwd,
      environment: environment,
      targetId: targetId,
      actionId: actionId,
    );
  }

  Future<int> run({
    required WorkspaceContext ctx,
    required String targetId,
    required String actionId,
    List<String> extraArgs = const [],
  }) async {
    try {
      final plan = await resolveLaunch(
        ctx: ctx,
        targetId: targetId,
        actionId: actionId,
        extraArgs: extraArgs,
      );
      return _process.run(
        plan.command,
        plan.args,
        workingDirectory: plan.workingDirectory,
        environment: plan.environment,
      );
    } on ActionLaunchException catch (e) {
      stderr.writeln(e.message);
      return e.exitCode;
    }
  }

  /// Human-readable reason an action cannot run now, or null if enabled.
  String? disabledReason({
    required ActionSpec spec,
    required WorkspaceContext ctx,
    required String targetId,
  }) {
    if (!isPlatformAllowed(spec.platforms)) {
      return 'Requires platform: ${spec.platforms.join(', ')}';
    }
    if (spec.requireEnvironments.isNotEmpty &&
        !spec.requireEnvironments.contains(ctx.environment.id)) {
      return 'Requires env ${spec.requireEnvironments.join('|')} '
          '(now: ${ctx.environment.id})';
    }
    if (spec.requireRailwayEnvironment) {
      final railway = ctx.environment.railwayEnvironment;
      if (railway == null || railway.isEmpty) {
        return 'Requires Railway env — switch to staging|production';
      }
    }
    final binding = ctx.environment.binding(targetId);
    final envFile = binding?.envFile;
    if (spec.requireEnvFile &&
        (envFile == null || !envFile.existsSync())) {
      return 'Missing synced .env — run sync for $targetId '
          '(${ctx.profileId}/${ctx.environment.id})';
    }
    return null;
  }

  static bool isPlatformAllowed(List<String> platforms) {
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
      throw ActionLaunchException(
        'ERROR: Supabase not reachable at $url\n'
        '       Run: supabase start && vet45 sync',
      );
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
