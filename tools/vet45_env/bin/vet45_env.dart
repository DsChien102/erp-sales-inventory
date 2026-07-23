import 'dart:convert';
import 'dart:io';

import 'package:vet45_env/tui/app.dart';
import 'package:vet45_env/tui/launch_mode.dart';
import 'package:vet45_env/completion_service.dart';
import 'package:vet45_env/config_init_service.dart';
import 'package:vet45_env/doctor_service.dart';
import 'package:vet45_env/link_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_init_service.dart';
import 'package:vet45_env/profile_registry.dart';
import 'package:vet45_env/run_service.dart';
import 'package:vet45_env/switch_command_args.dart';
import 'package:vet45_env/supabase_command_args.dart';
import 'package:vet45_env/supabase_delegate_service.dart';
import 'package:vet45_env/sync_service.dart';

Future<void> main(List<String> args) async {
  final mode = parseLaunchMode(args);
  if (mode == LaunchMode.help) {
    _printUsage();
    exit(0);
  }
  if (mode == LaunchMode.tui) {
    await runVet45Tui();
    return;
  }

  final rootPath = findRepoRoot();
  final root = Directory(rootPath);
  final command = args.first;
  final rest = args.skip(1).toList();

  if (command == 'init') {
    await _cmdInit(root, rest);
    return;
  }

  requireConfigInitialized(root);

  final manifest = EnvManifest.load(root);

  try {
    switch (command) {
      case 'list':
        _cmdList(manifest);
      case 'switch':
        await _cmdSwitch(manifest, rest);
      case 'use':
        await _cmdUse(manifest, rest);
      case 'use-and-sync':
        await _cmdUseAndSync(manifest, rest);
      case 'use-sync-run':
        await _cmdUseSyncRun(manifest, rest);
      case 'sync':
        await _cmdSync(manifest, rest);
      case 'link':
        await _cmdLink(manifest, rest);
      case 'doctor':
        await _cmdDoctor(manifest, rest);
      case 'resolve':
        _cmdResolve(manifest, rest);
      case 'resolve-shell':
        _cmdResolveShell(manifest, rest);
      case 'run':
        await _cmdRun(manifest, rest);
      case 'active':
      case 'status':
        _cmdActive(manifest);
      case 'profile':
        await _cmdProfile(manifest, rest);
      case 'supabase':
        await _cmdSupabase(manifest, rest);
      case 'completion':
        _cmdCompletion(manifest, rest);
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exit(64);
    }
  } on Object catch (e) {
    stderr.writeln('vet45 error: $e');
    exit(1);
  }
}

RunService _runService(EnvManifest manifest) {
  return RunService(
    manifest: manifest,
    syncService: SyncService(manifest: manifest),
    linkService: SupabaseLinkService(manifest: manifest),
    doctorService: DoctorService(manifest: manifest, skipNetwork: true),
  );
}

ActiveState _defaultState(EnvManifest manifest) => manifest.readState();

void _printUsage() {
  stdout.writeln('''
Usage: vet45 [<command> [args]]

With no arguments (or `tui`), opens the interactive TUI.

Commands:
  tui                  Open interactive TUI (default when no args)
  init <profileId> [--force] [--description "..."]
                       Scaffold .vet45/profiles/<profileId>/ from .vet45/templates/ and set active
  list                 List profiles, environments, and active selection
  switch [profile] [env] [--profile <id>] [--env <id>] [--target <id>]
                       Switch profile/env, supabase link, and sync (recommended)
  use <id>             Set active environment (and optional supabase link)
  use-and-sync <id> [--target <id>] [--profile <id>]
  use-sync-run <id> <target> <action> [args...]
  sync [--env <id>] [--target <id>] [--profile <id>]
  link [--env <id>] [--profile <id>]
  doctor [--env <id>] [--target <id>] [--profile <id>] [--offline]
  run <target> <action> [args...] [--env <id>] [--profile <id>]
  resolve [--env <id>] [--profile <id>]
  resolve-shell [--env <id>] [--profile <id>]
  active|status        Print active profile + environment
  profile list|use|init
  supabase [--profile <id>] [--env <id>] <args...>
                       Run supabase CLI with profile auth.env token (auto link)
  completion bash|zsh  Print shell completion script

Flags:
  --skip-link          Skip supabase link on use/sync/use-and-sync/switch/supabase
  --target <id>        Limit sync/doctor to one registered target
  --env <id>           Environment for sync/doctor/run
  --profile <id>       Configuration profile (secrets root / Supabase account)
  --offline            Skip network checks in doctor
''');
}

Future<void> _cmdInit(Directory root, List<String> args) async {
  final force = args.contains('--force');
  final filtered = args.where((a) => a != '--force').toList();
  final description = _parseDescriptionFlag(filtered);
  final withoutDesc = _withoutDescriptionFlag(filtered);
  String? profileId;
  for (final arg in withoutDesc) {
    if (!arg.startsWith('-')) {
      profileId = arg;
      break;
    }
  }
  if (profileId == null || profileId.isEmpty) {
    stderr.writeln('Usage: vet45 init <profileId> [--force] [--description "..."]');
    exit(64);
  }

  final service = ConfigInitService(repoRoot: root);
  try {
    final result = await service.init(
      profileId,
      force: force,
      description: description,
    );
    stdout.writeln('Initialized profile: ${result.profileId}');
    for (final path in result.created) {
      stdout.writeln('  created $path');
    }
    if (result.skipped.isNotEmpty) {
      stdout.writeln('  skipped ${result.skipped.length} existing file(s)');
    }
    stdout.writeln('  Active profile set to ${result.profileId}');
    stdout.writeln('');
    stdout.writeln(
      'Next: fill .vet45/profiles/${result.profileId}/*.env then: vet45 sync',
    );
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

void _cmdList(EnvManifest manifest) {
  final state = _defaultState(manifest);
  stdout.writeln(
    'Active: profile=${state.profileId} environment=${state.environmentId} '
    '(default env: ${manifest.defaultEnvironmentId})',
  );
  stdout.writeln('');
  stdout.writeln('Profiles (local .vet45/profiles/<id>/):');
  if (manifest.profiles.profiles.isEmpty) {
    stdout.writeln('  (none — run: vet45 init <profileId>)');
  }
  for (final entry in manifest.profiles.profiles.entries) {
    final marker = entry.key == state.profileId ? '*' : ' ';
    final profile = entry.value;
    stdout.writeln(
      '$marker ${entry.key.padRight(12)} ${profile.description}\n'
      '             secrets: ${profile.secretsRoot}',
    );
  }
  stdout.writeln('');
  stdout.writeln('Targets:');
  for (final entry in manifest.targets.entries) {
    final t = entry.value;
    final keys = t.keys.map((k) => k.name).join(', ');
    final manifestPath = t.manifestFile != null
        ? _relativePath(manifest.rootDir, t.manifestFile!)
        : '(unknown)';
    stdout.writeln(
      '  ${entry.key.padRight(10)} ${t.description}'
      '${t.writeEnvFile ? '' : ' (secrets-only)'}'
      '\n             manifest: $manifestPath'
      '\n             keys: $keys',
    );
  }
  stdout.writeln('');
  stdout.writeln('Environments:');
  for (final entry in manifest.environments.entries) {
    final marker = entry.key == state.environmentId ? '*' : ' ';
    final env = entry.value;
    final bindingLines = env.bindings.entries.map((b) {
      final path = b.value.envFile?.path ?? '(no envFile)';
      return '    ${b.key}: $path';
    }).join('\n');
    stdout.writeln(
      '$marker ${entry.key.padRight(12)} ${env.description}\n$bindingLines',
    );
  }
}

String _relativePath(Directory root, File file) {
  final rootPath = root.path.endsWith(Platform.pathSeparator)
      ? root.path
      : '${root.path}${Platform.pathSeparator}';
  if (file.path.startsWith(rootPath)) {
    return file.path.substring(rootPath.length).replaceAll('\\', '/');
  }
  return file.path;
}

void _cmdActive(EnvManifest manifest) {
  final state = _defaultState(manifest);
  stdout.writeln('profile=${state.profileId}');
  stdout.writeln('environment=${state.environmentId}');
}

Future<void> _cmdSwitch(EnvManifest manifest, List<String> args) async {
  final parsed = SwitchCommandArgs.parse(args, manifest);
  if (parsed.statusOnly) {
    _cmdActive(manifest);
    return;
  }
  await _runService(manifest).switchWorkspace(
    profileId: parsed.profileId,
    environmentId: parsed.environmentId,
    targetId: parsed.targetId,
    skipLink: parsed.skipLink,
  );
}

void _cmdCompletion(EnvManifest manifest, List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: completion bash|zsh');
    exit(64);
  }
  final shell = args.first;
  try {
    stdout.write(CompletionService(manifest: manifest).render(shell));
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
}

Future<void> _cmdProfile(EnvManifest manifest, List<String> args) async {
  if (args.isEmpty || args.first == '--help') {
    stderr.writeln('Usage: profile list|use <id>|init <id>');
    exit(64);
  }
  switch (args.first) {
    case 'list':
      _cmdList(manifest);
    case 'use':
      final filtered = args.skip(1).toList();
      final id = _parseProfileIdArg(filtered, manifest);
      await _runService(manifest).useProfile(id);
    case 'init':
      final filtered = args.skip(1).where((a) => a != '--skip-link').toList();
      final id = _parseProfileIdArg(filtered, manifest);
      final description = _parseDescriptionFlag(filtered);
      await ProfileInitService(manifest: manifest).init(id, description: description);
    default:
      stderr.writeln('Unknown profile command: ${args.first}');
      exit(64);
  }
}

Future<void> _cmdSupabase(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  final parsed = SupabaseCommandArgs.parse(
    filtered,
    defaultEnvironmentId: _defaultState(manifest).environmentId,
  );
  if (parsed.supabaseArgs.isEmpty) {
    stderr.writeln(
      'Usage: supabase [--profile <id>] [--env <id>] [--skip-link] <supabase-args...>',
    );
    exit(64);
  }
  final ctx = manifest.context(
    profileId: parsed.profileId,
    environmentId: parsed.environmentId,
  );
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(ctx))
        .printSummary();
  }
  final code = await SupabaseDelegateService(manifest: manifest).run(
    ctx,
    parsed.supabaseArgs,
  );
  exit(code);
}

Future<void> _cmdUse(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  final profileId = _parseProfileFlag(filtered);
  final id = _parseIdArg(filtered, manifest);
  final ctx = manifest.context(profileId: profileId, environmentId: id);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(ctx))
        .printSummary();
  }
  writeActiveState(
    manifest.rootDir,
    ActiveState(profileId: ctx.profileId, environmentId: id),
  );
  stdout.writeln('Active: profile=${ctx.profileId} environment=$id');
}

Future<void> _cmdUseAndSync(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  final profileId = _parseProfileFlag(filtered);
  final targetId = _parseTargetFlag(filtered);
  final id = _parseIdArg(filtered, manifest);
  await _runService(manifest).useAndSync(
    id,
    profileId: profileId,
    targetId: targetId,
    skipLink: skipLink,
  );
}

Future<void> _cmdUseSyncRun(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  if (filtered.length < 3) {
    stderr.writeln('Usage: use-sync-run <env> <target> <action> [args...]');
    exit(64);
  }
  final profileId = _parseProfileFlag(filtered);
  final envId = filtered[0];
  final target = filtered[1];
  final action = filtered[2];
  final extra = _extraArgsAfterFlags(filtered.skip(3).toList());
  final code = await _runService(manifest).useSyncRun(
    envId,
    target,
    action,
    profileId: profileId,
    extraArgs: extra,
    skipLink: skipLink,
  );
  if (code != 0) {
    exit(code);
  }
}

Future<void> _cmdRun(EnvManifest manifest, List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: run <target> <action> [args...]');
    exit(64);
  }
  final target = args[0];
  final action = args[1];
  final rest = args.skip(2).toList();
  final profileId = _parseProfileFlag(rest);
  final envId = _hasEnvFlag(rest) ? _parseEnvFlag(rest, manifest) : null;
  final extra = _extraArgsAfterFlags(rest);
  final code = await _runService(manifest).run(
    target,
    action,
    extraArgs: extra,
    profileId: profileId,
    environmentId: envId,
  );
  if (code != 0) {
    exit(code);
  }
}

bool _hasEnvFlag(List<String> args) => args.contains('--env');

Future<void> _cmdSync(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  final profileId = _parseProfileFlag(filtered);
  final targetId = _parseTargetFlag(filtered);
  final envId = _parseEnvFlag(_withoutTargetFlag(_withoutProfileFlag(filtered)), manifest);
  final ctx = manifest.context(profileId: profileId, environmentId: envId);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(ctx))
        .printSummary();
  }
  final result = await SyncService(manifest: manifest).sync(ctx, targetId: targetId);
  stdout.writeln(
    'Synced profile=${result.profileId} environment=${result.environmentId}',
  );
  if (result.writtenFiles.isEmpty && result.failures.isEmpty) {
    stdout.writeln('  (no writable targets)');
  }
  for (final entry in result.writtenFiles.entries) {
    stdout.writeln('  OK   ${entry.key}: ${entry.value.path}');
  }
  for (final entry in result.failures.entries) {
    stderr.writeln('  FAIL ${entry.key}: ${entry.value}');
  }
  if (!result.ok) {
    exit(1);
  }
}

Future<void> _cmdLink(EnvManifest manifest, List<String> args) async {
  final profileId = _parseProfileFlag(args);
  final envId = _parseEnvFlag(_withoutProfileFlag(args), manifest);
  final ctx = manifest.context(profileId: profileId, environmentId: envId);
  (await SupabaseLinkService(manifest: manifest).ensureLinked(ctx))
      .printSummary();
}

String _parseProfileIdArg(List<String> args, EnvManifest manifest) {
  final fromFlag = _parseProfileFlag(args);
  if (fromFlag != null) {
    return fromFlag;
  }
  for (var i = 0; i < args.length; i++) {
    if (_isFlagWithValue(args, i)) {
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      return args[i];
    }
  }
  throw StateError(
    'Profile id required. Usage: profile use <id> | profile init <id>',
  );
}

List<String> _withoutDescriptionFlag(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--description') {
      i++;
      continue;
    }
    result.add(args[i]);
  }
  return result;
}

String _parseIdArg(List<String> args, EnvManifest manifest) {
  for (var i = 0; i < args.length; i++) {
    if (_isFlagWithValue(args, i)) {
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      return args[i];
    }
  }
  return manifest.defaultEnvironmentId;
}

String _parseEnvFlag(List<String> args, EnvManifest manifest) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--env' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (_isFlagWithValue(args, i)) {
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      return args[i];
    }
  }
  return _defaultState(manifest).environmentId;
}

String? _parseProfileFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--profile' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String? _parseDescriptionFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--description' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

List<String> _extraArgsAfterFlags(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (_isFlagWithValue(args, i)) {
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      result.add(args[i]);
    }
  }
  return result;
}

String? _parseTargetFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--target' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

bool _isFlagWithValue(List<String> args, int i) {
  return (args[i] == '--target' ||
          args[i] == '--env' ||
          args[i] == '--profile' ||
          args[i] == '--description') &&
      i + 1 < args.length;
}

List<String> _withoutTargetFlag(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--target') {
      i++;
      continue;
    }
    result.add(args[i]);
  }
  return result;
}

List<String> _withoutProfileFlag(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--profile') {
      i++;
      continue;
    }
    result.add(args[i]);
  }
  return result;
}

Future<void> _cmdDoctor(EnvManifest manifest, List<String> args) async {
  final skipNetwork = args.contains('--offline');
  final filtered = args.where((a) => a != '--offline').toList();
  final profileId = _parseProfileFlag(filtered);
  final targetId = _parseTargetFlag(filtered);
  final envId = _parseEnvFlag(
    _withoutTargetFlag(_withoutProfileFlag(filtered)),
    manifest,
  );
  final ctx = manifest.context(profileId: profileId, environmentId: envId);
  final report = await DoctorService(
    manifest: manifest,
    skipNetwork: skipNetwork,
  ).run(ctx, targetId: targetId);
  report.printReport();
  if (!report.ok) {
    exit(1);
  }
}

void _cmdResolve(EnvManifest manifest, List<String> args) {
  final profileId = _parseProfileFlag(args);
  final envId = _parseEnvFlag(_withoutProfileFlag(args), manifest);
  final ctx = manifest.context(profileId: profileId, environmentId: envId);
  final payload = ctx.environment.toResolveJson(manifest.targets, ctx);
  stdout.writeln(jsonEncode(payload));
}

void _cmdResolveShell(EnvManifest manifest, List<String> args) {
  final profileId = _parseProfileFlag(args);
  final envId = _parseEnvFlag(_withoutProfileFlag(args), manifest);
  final ctx = manifest.context(profileId: profileId, environmentId: envId);
  final env = ctx.environment;
  stdout.writeln('VET45_PROFILE=${ctx.profileId}');
  stdout.writeln('VET45_ENV_ID=${env.id}');
  stdout.writeln('SECRETS_ROOT=${ctx.profile.secretsRoot}');
  stdout.writeln('SECRETS_FILE=${ctx.secretsFile.path}');
  stdout.writeln('AUTH_FILE=${ctx.authFile.path}');

  for (final entry in env.bindings.entries) {
    final binding = entry.value;
    final envFile = binding.envFile;
    if (envFile != null) {
      stdout.writeln('TARGET_${entry.key}_ENV_FILE=${envFile.path}');
    }
    for (final field in binding.fields.entries) {
      final key = field.key
          .replaceAllMapped(
            RegExp(r'([a-z])([A-Z])'),
            (m) => '${m[1]}_${m[2]}',
          )
          .toUpperCase();
      stdout.writeln('TARGET_${entry.key}_$key=${field.value}');
    }
  }

  for (final entry in manifest.targets.entries) {
    final target = entry.value;
    if (!target.writeEnvFile && target.secretsFile != null) {
      stdout.writeln(
        'TARGET_${entry.key}_SECRETS_FILE=${target.secretsFile!.path}',
      );
    }
  }

  final railway = env.railwayEnvironment;
  if (railway != null && railway.isNotEmpty) {
    stdout.writeln('RAILWAY_ENVIRONMENT=$railway');
  }
}
