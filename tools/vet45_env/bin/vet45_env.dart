import 'dart:convert';
import 'dart:io';

import 'package:vet45_env/doctor_service.dart';
import 'package:vet45_env/link_service.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/sync_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    exit(0);
  }

  final rootPath = findRepoRoot();
  final root = Directory(rootPath);
  final manifest = EnvManifest.load(root);
  final command = args.first;
  final rest = args.skip(1).toList();

  try {
    switch (command) {
      case 'list':
        _cmdList(manifest);
      case 'use':
        await _cmdUse(manifest, rest);
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
      case 'active':
        stdout.writeln(readActive(root) ?? manifest.defaultEnvironmentId);
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        exit(64);
    }
  } on Object catch (e) {
    stderr.writeln('vet45_env error: $e');
    exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tools/vet45_env <command> [args]

Commands:
  list                 List environments and active selection
  use <id>             Set active environment and align supabase link
  sync [--env <id>]    Align supabase link + generate ERP + worker .env files
  link [--env <id>]    Align supabase link only (no env file sync)
  doctor [--env <id>]  Validate configuration
  resolve [--env <id>] Print JSON paths (flavor, env files)
  resolve-shell [--env <id>] Print shell KEY=value lines for scripts
  active               Print active environment id

Flags:
  --skip-link          Skip supabase link on use/sync
''');
}

void _cmdList(EnvManifest manifest) {
  final active = readActive(manifest.rootDir) ?? manifest.defaultEnvironmentId;
  stdout.writeln('Active: $active (default: ${manifest.defaultEnvironmentId})');
  stdout.writeln('');
  for (final entry in manifest.environments.entries) {
    final marker = entry.key == active ? '*' : ' ';
    final env = entry.value;
    stdout.writeln(
      '$marker ${entry.key.padRight(12)} ${env.description}\n'
      '    erp:    ${env.erp.flavor} → ${env.erp.envFile.path}\n'
      '    worker: ${env.worker.envFile.path}',
    );
  }
}

Future<void> _cmdUse(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final id = _parseIdArg(args, manifest);
  manifest.getEnvironment(id);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(id)).printSummary();
  }
  writeActive(manifest.rootDir, id);
  stdout.writeln('Active environment: $id');
}

Future<void> _cmdSync(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final id = _parseEnvFlag(args.where((a) => a != '--skip-link').toList(), manifest);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(id)).printSummary();
  }
  final result = await SyncService(manifest: manifest).sync(id);
  stdout.writeln('Synced environment: ${result.environmentId}');
  stdout.writeln('  ERP:    ${result.erpEnvFile.path}');
  stdout.writeln('  Worker: ${result.workerEnvFile.path}');
}

Future<void> _cmdLink(EnvManifest manifest, List<String> args) async {
  final id = _parseEnvFlag(args, manifest);
  (await SupabaseLinkService(manifest: manifest).ensureLinked(id)).printSummary();
}

String _parseIdArg(List<String> args, EnvManifest manifest) {
  for (final arg in args) {
    if (!arg.startsWith('-')) {
      return arg;
    }
  }
  return manifest.defaultEnvironmentId;
}

String _parseEnvFlag(List<String> args, EnvManifest manifest) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--env' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (!args[i].startsWith('-')) {
      return args[i];
    }
  }
  return readActive(manifest.rootDir) ?? manifest.defaultEnvironmentId;
}

Future<void> _cmdDoctor(EnvManifest manifest, List<String> args) async {
  final skipNetwork = args.contains('--offline');
  final id = _parseEnvFlag(args.where((a) => a != '--offline').toList(), manifest);
  final report = await DoctorService(
    manifest: manifest,
    skipNetwork: skipNetwork,
  ).run(id);
  report.printReport();
  if (!report.ok) {
    exit(1);
  }
}

void _cmdResolve(EnvManifest manifest, List<String> args) {
  final id = _parseEnvFlag(args, manifest);
  final env = manifest.getEnvironment(id);
  stdout.writeln(jsonEncode(env.toResolveJson()));
}

void _cmdResolveShell(EnvManifest manifest, List<String> args) {
  final id = _parseEnvFlag(args, manifest);
  final env = manifest.getEnvironment(id);
  stdout.writeln('VET45_ENV_ID=$id');
  stdout.writeln('ERP_FLAVOR=${env.erp.flavor}');
  stdout.writeln('ERP_ENV_FILE=${env.erp.envFile.path}');
  stdout.writeln('ERP_ENV_BASENAME=${env.erp.envFile.uri.pathSegments.last}');
  stdout.writeln('WORKER_ENV_FILE=${env.worker.envFile.path}');
  final dockerUrl = env.worker.dockerSupabaseUrl;
  if (dockerUrl != null && dockerUrl.isNotEmpty) {
    stdout.writeln('WORKER_DOCKER_SUPABASE_URL=$dockerUrl');
  }
  final railway = env.railwayEnvironment;
  if (railway != null && railway.isNotEmpty) {
    stdout.writeln('RAILWAY_ENVIRONMENT=$railway');
  }
}
