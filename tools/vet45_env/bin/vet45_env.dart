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
  sync [--env <id>] [--target <id>]
                       Align supabase link + generate target .env files
  link [--env <id>]    Align supabase link only (no env file sync)
  doctor [--env <id>] [--target <id>] [--offline]
                       Validate configuration (per-target key deps)
  resolve [--env <id>] Print JSON paths (flavor, env files)
  resolve-shell [--env <id>] Print shell KEY=value lines for scripts
  active               Print active environment id

Flags:
  --skip-link          Skip supabase link on use/sync
  --target <id>        Limit sync/doctor to one registered target (erp, worker, deploy)
  --offline            Skip network checks in doctor
''');
}

void _cmdList(EnvManifest manifest) {
  final active = readActive(manifest.rootDir) ?? manifest.defaultEnvironmentId;
  stdout.writeln('Active: $active (default: ${manifest.defaultEnvironmentId})');
  stdout.writeln('');
  stdout.writeln('Targets:');
  for (final entry in manifest.targets.entries) {
    final t = entry.value;
    final keys = t.keys.map((k) => k.name).join(', ');
    stdout.writeln(
      '  ${entry.key.padRight(10)} ${t.description}'
      '${t.writeEnvFile ? '' : ' (secrets-only)'}'
      '\n             keys: $keys',
    );
  }
  stdout.writeln('');
  for (final entry in manifest.environments.entries) {
    final marker = entry.key == active ? '*' : ' ';
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

Future<void> _cmdUse(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final id = _parseIdArg(args, manifest);
  manifest.getEnvironment(id);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(id))
        .printSummary();
  }
  writeActive(manifest.rootDir, id);
  stdout.writeln('Active environment: $id');
}

Future<void> _cmdSync(EnvManifest manifest, List<String> args) async {
  final skipLink = args.contains('--skip-link');
  final filtered = args.where((a) => a != '--skip-link').toList();
  final targetId = _parseTargetFlag(filtered);
  final id = _parseEnvFlag(_withoutTargetFlag(filtered), manifest);
  if (!skipLink) {
    (await SupabaseLinkService(manifest: manifest).ensureLinked(id))
        .printSummary();
  }
  final result = await SyncService(manifest: manifest).sync(
    id,
    targetId: targetId,
  );
  stdout.writeln('Synced environment: ${result.environmentId}');
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
  final id = _parseEnvFlag(args, manifest);
  (await SupabaseLinkService(manifest: manifest).ensureLinked(id))
      .printSummary();
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
    if (args[i] == '--target') {
      // skip value
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      return args[i];
    }
  }
  return readActive(manifest.rootDir) ?? manifest.defaultEnvironmentId;
}

String? _parseTargetFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--target' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
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

Future<void> _cmdDoctor(EnvManifest manifest, List<String> args) async {
  final skipNetwork = args.contains('--offline');
  final filtered = args.where((a) => a != '--offline').toList();
  final targetId = _parseTargetFlag(filtered);
  final id = _parseEnvFlag(_withoutTargetFlag(filtered), manifest);
  final report = await DoctorService(
    manifest: manifest,
    skipNetwork: skipNetwork,
  ).run(id, targetId: targetId);
  report.printReport();
  if (!report.ok) {
    exit(1);
  }
}

void _cmdResolve(EnvManifest manifest, List<String> args) {
  final id = _parseEnvFlag(args, manifest);
  final env = manifest.getEnvironment(id);
  final payload = env.toResolveJson(manifest.targets);
  payload['deploySecretsFile'] = manifest.deploySecretsFile.path;
  stdout.writeln(jsonEncode(payload));
}

void _cmdResolveShell(EnvManifest manifest, List<String> args) {
  final id = _parseEnvFlag(args, manifest);
  final env = manifest.getEnvironment(id);
  stdout.writeln('VET45_ENV_ID=$id');
  stdout.writeln('SECRETS_FILE=${env.secretsFile.path}');
  stdout.writeln('DEPLOY_SECRETS_FILE=${manifest.deploySecretsFile.path}');

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

  // Backward-compatible aliases for Melos / deploy scripts.
  final erp = env.erp;
  if (erp != null) {
    if (erp.flavor != null) {
      stdout.writeln('ERP_FLAVOR=${erp.flavor}');
    }
    if (erp.envFile != null) {
      stdout.writeln('ERP_ENV_FILE=${erp.envFile!.path}');
      stdout.writeln(
        'ERP_ENV_BASENAME=${erp.envFile!.uri.pathSegments.last}',
      );
    }
  }
  final worker = env.worker;
  if (worker != null) {
    if (worker.envFile != null) {
      stdout.writeln('WORKER_ENV_FILE=${worker.envFile!.path}');
    }
    final dockerUrl = worker.dockerSupabaseUrl;
    if (dockerUrl != null && dockerUrl.isNotEmpty) {
      stdout.writeln('WORKER_DOCKER_SUPABASE_URL=$dockerUrl');
    }
  }

  final railway = env.railwayEnvironment;
  if (railway != null && railway.isNotEmpty) {
    stdout.writeln('RAILWAY_ENVIRONMENT=$railway');
  }
}
