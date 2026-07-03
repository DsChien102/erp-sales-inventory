import 'dart:convert';
import 'dart:io';

/// Loaded [config/environments.json] with validation.
class EnvManifest {
  EnvManifest({
    required this.defaultEnvironmentId,
    required this.environments,
    required this.rootDir,
    required this.deploySecretsFile,
  });

  final String defaultEnvironmentId;
  final Map<String, EnvironmentDefinition> environments;
  final Directory rootDir;
  final File deploySecretsFile;

  static EnvManifest load(Directory rootDir) {
    final file = File('${rootDir.path}/config/environments.json');
    if (!file.existsSync()) {
      throw StateError('Missing manifest: ${file.path}');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final defaultId = json['default'] as String? ?? 'development';
    final rawEnvs = json['environments'] as Map<String, dynamic>? ?? {};
    final environments = <String, EnvironmentDefinition>{};
    for (final entry in rawEnvs.entries) {
      environments[entry.key] = EnvironmentDefinition.fromJson(
        id: entry.key,
        json: entry.value as Map<String, dynamic>,
        rootDir: rootDir,
      );
    }
    if (environments.isEmpty) {
      throw StateError('environments.json has no environments');
    }
    if (!environments.containsKey(defaultId)) {
      throw StateError('default environment "$defaultId" not found in manifest');
    }
    final deployRelative =
        json['deploySecretsFile'] as String? ?? 'config/secrets/deploy.env';
    return EnvManifest(
      defaultEnvironmentId: defaultId,
      environments: environments,
      rootDir: rootDir,
      deploySecretsFile: File('${rootDir.path}/$deployRelative'),
    );
  }

  EnvironmentDefinition getEnvironment(String id) {
    final env = environments[id];
    if (env == null) {
      throw ArgumentError('Unknown environment: $id');
    }
    return env;
  }

  EnvironmentDefinition resolve(String? id) {
    return getEnvironment(id ?? readActive(rootDir) ?? defaultEnvironmentId);
  }
}

class EnvironmentDefinition {
  EnvironmentDefinition({
    required this.id,
    required this.description,
    required this.secretsFile,
    required this.supabaseSource,
    required this.erp,
    required this.worker,
    this.railwayEnvironment,
    this.cliFallback = false,
    this.syncSupabaseLink = true,
    this.supabaseProjectRef,
  });

  final String id;
  final String description;
  final File secretsFile;
  final String supabaseSource;
  final ErpTarget erp;
  final WorkerTarget worker;
  final String? railwayEnvironment;
  final bool cliFallback;
  final bool syncSupabaseLink;
  final String? supabaseProjectRef;

  factory EnvironmentDefinition.fromJson({
    required String id,
    required Map<String, dynamic> json,
    required Directory rootDir,
  }) {
    final erpJson = json['erp'] as Map<String, dynamic>? ?? {};
    final workerJson = json['worker'] as Map<String, dynamic>? ?? {};
    final secretsRelative = json['secretsFile'] as String? ?? 'config/secrets/$id.env';
    return EnvironmentDefinition(
      id: id,
      description: json['description'] as String? ?? id,
      secretsFile: File('${rootDir.path}/$secretsRelative'),
      supabaseSource: json['supabaseSource'] as String? ?? 'secrets',
      railwayEnvironment: json['railwayEnvironment'] as String?,
      cliFallback: json['cliFallback'] as bool? ?? false,
      syncSupabaseLink: json['syncSupabaseLink'] as bool? ??
          (json['supabaseSource'] as String? ?? 'secrets') != 'supabase_cli',
      supabaseProjectRef: json['supabaseProjectRef'] as String?,
      erp: ErpTarget(
        flavor: erpJson['flavor'] as String? ?? 'development',
        envFile: File('${rootDir.path}/${erpJson['envFile']}'),
        appEnv: erpJson['appEnv'] as String? ?? 'development',
      ),
      worker: WorkerTarget(
        envFile: File('${rootDir.path}/${workerJson['envFile']}'),
        dockerSupabaseUrl: workerJson['dockerSupabaseUrl'] as String?,
      ),
    );
  }

  Map<String, dynamic> toResolveJson() => {
        'id': id,
        'description': description,
        'supabaseSource': supabaseSource,
        'railwayEnvironment': railwayEnvironment,
        'erp': {
          'flavor': erp.flavor,
          'envFile': erp.envFile.path,
          'appEnv': erp.appEnv,
        },
        'worker': {
          'envFile': worker.envFile.path,
          'dockerSupabaseUrl': worker.dockerSupabaseUrl,
        },
        'secretsFile': secretsFile.path,
        'cliFallback': cliFallback,
        'syncSupabaseLink': syncSupabaseLink,
        if (supabaseProjectRef != null) 'supabaseProjectRef': supabaseProjectRef,
      };
}

class ErpTarget {
  ErpTarget({
    required this.flavor,
    required this.envFile,
    required this.appEnv,
  });

  final String flavor;
  final File envFile;
  final String appEnv;
}

class WorkerTarget {
  WorkerTarget({
    required this.envFile,
    this.dockerSupabaseUrl,
  });

  final File envFile;
  final String? dockerSupabaseUrl;
}

File activeFile(Directory rootDir) => File('${rootDir.path}/.vet45/active');

String? readActive(Directory rootDir) {
  final file = activeFile(rootDir);
  if (!file.existsSync()) {
    return null;
  }
  final value = file.readAsStringSync().trim();
  return value.isEmpty ? null : value;
}

void writeActive(Directory rootDir, String environmentId) {
  final dir = Directory('${rootDir.path}/.vet45');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  activeFile(rootDir).writeAsStringSync('$environmentId\n');
}

String findRepoRoot({String? start}) {
  var dir = Directory(start ?? Directory.current.path);
  while (true) {
    if (File('${dir.path}/config/environments.json').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not find repo root (config/environments.json). '
        'Run from the Vet45 monorepo.',
      );
    }
    dir = parent;
  }
}
