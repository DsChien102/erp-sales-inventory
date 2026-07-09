import 'dart:convert';
import 'dart:io';

import 'profile_registry.dart';
export 'repo_root.dart';

/// Loaded [config/environments.json] with validation.
class EnvManifest {
  EnvManifest({
    required this.defaultEnvironmentId,
    required this.targets,
    required this.environments,
    required this.rootDir,
    required this.deploySecretsFile,
    required this.profiles,
  });

  final String defaultEnvironmentId;
  final Map<String, TargetDefinition> targets;
  final Map<String, EnvironmentDefinition> environments;
  final Directory rootDir;
  final File deploySecretsFile;
  final ProfileRegistry profiles;

  static EnvManifest load(Directory rootDir) {
    final file = File('${rootDir.path}/config/environments.json');
    if (!file.existsSync()) {
      throw StateError('Missing manifest: ${file.path}');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final defaultId = json['default'] as String? ?? 'development';

    final targets = _loadTargets(json, rootDir);
    if (targets.isEmpty) {
      throw StateError('environments.json has no targets');
    }

    final rawEnvs = json['environments'] as Map<String, dynamic>? ?? {};
    final environments = <String, EnvironmentDefinition>{};
    for (final entry in rawEnvs.entries) {
      environments[entry.key] = EnvironmentDefinition.fromJson(
        id: entry.key,
        json: entry.value as Map<String, dynamic>,
        rootDir: rootDir,
        targets: targets,
      );
    }
    if (environments.isEmpty) {
      throw StateError('environments.json has no environments');
    }
    if (!environments.containsKey(defaultId)) {
      throw StateError('default environment "$defaultId" not found in manifest');
    }

    final deployTarget = targets['deploy'];
    final deployRelative = deployTarget?.secretsFileRelative ??
        json['deploySecretsFile'] as String? ??
        'config/secrets/deploy.env';

    return EnvManifest(
      defaultEnvironmentId: defaultId,
      targets: targets,
      environments: environments,
      rootDir: rootDir,
      deploySecretsFile: File('${rootDir.path}/$deployRelative'),
      profiles: ProfileRegistry.load(rootDir),
    );
  }

  static Map<String, TargetDefinition> _loadTargets(
    Map<String, dynamic> json,
    Directory rootDir,
  ) {
    final raw = json['targets'] as Map<String, dynamic>? ?? {};
    final targets = <String, TargetDefinition>{};
    for (final entry in raw.entries) {
      targets[entry.key] = TargetDefinition.fromJson(
        id: entry.key,
        json: entry.value as Map<String, dynamic>,
        rootDir: rootDir,
      );
    }
    return targets;
  }

  TargetDefinition getTarget(String id) {
    final target = targets[id];
    if (target == null) {
      throw ArgumentError('Unknown target: $id');
    }
    return target;
  }

  EnvironmentDefinition getEnvironment(String id) {
    final env = environments[id];
    if (env == null) {
      throw ArgumentError('Unknown environment: $id');
    }
    return env;
  }

  WorkspaceContext context({
    String? profileId,
    String? environmentId,
  }) {
    return WorkspaceContext.resolve(
      manifest: this,
      profileId: profileId,
      environmentId: environmentId,
    );
  }

  EnvironmentDefinition resolveEnvironment(String? id) {
    final state = readActiveState(
      rootDir,
      defaultProfileId: profiles.defaultProfileId,
      defaultEnvironmentId: defaultEnvironmentId,
    );
    return getEnvironment(id ?? state.environmentId);
  }
}

class TargetDefinition {
  TargetDefinition({
    required this.id,
    required this.description,
    required this.keys,
    this.writeEnvFile = true,
    this.secretsFileRelative,
    this.secretsFile,
  });

  final String id;
  final String description;
  final List<TargetKeySpec> keys;
  final bool writeEnvFile;

  /// Relative path when this target uses its own secrets file (e.g. deploy).
  final String? secretsFileRelative;
  final File? secretsFile;

  factory TargetDefinition.fromJson({
    required String id,
    required Map<String, dynamic> json,
    required Directory rootDir,
  }) {
    final keysJson = json['keys'] as List<dynamic>? ?? [];
    final secretsRelative = json['secretsFile'] as String?;
    return TargetDefinition(
      id: id,
      description: json['description'] as String? ?? id,
      writeEnvFile: json['writeEnvFile'] as bool? ?? true,
      secretsFileRelative: secretsRelative,
      secretsFile: secretsRelative == null
          ? null
          : File('${rootDir.path}/$secretsRelative'),
      keys: keysJson
          .map((e) => TargetKeySpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Secrets source for this target (shared deploy file or profile env secrets).
  File secretsSource(WorkspaceContext ctx) =>
      secretsFile ?? ctx.secretsFile;
}

class TargetKeySpec {
  TargetKeySpec({
    required this.name,
    this.from,
    this.fromManifest,
    this.required = false,
    this.defaultValue,
    this.autoGenerate = false,
  });

  final String name;
  final String? from;
  final String? fromManifest;
  final bool required;
  final String? defaultValue;
  final bool autoGenerate;

  String get sourceKey => from ?? name;

  factory TargetKeySpec.fromJson(Map<String, dynamic> json) {
    return TargetKeySpec(
      name: json['name'] as String,
      from: json['from'] as String?,
      fromManifest: json['fromManifest'] as String?,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'] as String?,
      autoGenerate: json['autoGenerate'] as bool? ?? false,
    );
  }
}

class TargetBinding {
  TargetBinding({
    required this.targetId,
    this.envFile,
    Map<String, String>? fields,
  }) : fields = fields ?? {};

  final String targetId;
  final File? envFile;
  final Map<String, String> fields;

  String? get flavor => fields['flavor'];
  String? get appEnv => fields['appEnv'];
  String? get dockerSupabaseUrl => fields['dockerSupabaseUrl'];

  factory TargetBinding.fromJson({
    required String targetId,
    required Map<String, dynamic> json,
    required Directory rootDir,
  }) {
    final envFileRelative = json['envFile'] as String?;
    final fields = <String, String>{};
    for (final entry in json.entries) {
      if (entry.key == 'envFile') {
        continue;
      }
      final value = entry.value;
      if (value is String) {
        fields[entry.key] = value;
      } else if (value != null) {
        fields[entry.key] = value.toString();
      }
    }
    return TargetBinding(
      targetId: targetId,
      envFile: envFileRelative == null
          ? null
          : File('${rootDir.path}/$envFileRelative'),
      fields: fields,
    );
  }
}

class EnvironmentDefinition {
  EnvironmentDefinition({
    required this.id,
    required this.description,
    required this.supabaseSource,
    required this.bindings,
    this.railwayEnvironment,
    this.cliFallback = false,
    this.syncSupabaseLink = true,
    this.supabaseProjectRef,
  });

  final String id;
  final String description;
  final String supabaseSource;
  final Map<String, TargetBinding> bindings;
  final String? railwayEnvironment;
  final bool cliFallback;
  final bool syncSupabaseLink;
  final String? supabaseProjectRef;

  TargetBinding? binding(String targetId) => bindings[targetId];

  TargetBinding? get erp => bindings['erp'];
  TargetBinding? get worker => bindings['worker'];

  factory EnvironmentDefinition.fromJson({
    required String id,
    required Map<String, dynamic> json,
    required Directory rootDir,
    required Map<String, TargetDefinition> targets,
  }) {
    final rawBindings = json['targets'] as Map<String, dynamic>? ?? {};
    final bindings = <String, TargetBinding>{};
    for (final entry in rawBindings.entries) {
      if (!targets.containsKey(entry.key)) {
        throw StateError(
          'Environment "$id" references unknown target "${entry.key}"',
        );
      }
      bindings[entry.key] = TargetBinding.fromJson(
        targetId: entry.key,
        json: entry.value as Map<String, dynamic>,
        rootDir: rootDir,
      );
    }

    for (final entry in bindings.entries) {
      final target = targets[entry.key]!;
      if (target.writeEnvFile && entry.value.envFile == null) {
        throw StateError(
          'Environment "$id" target "${entry.key}" requires envFile',
        );
      }
    }

    return EnvironmentDefinition(
      id: id,
      description: json['description'] as String? ?? id,
      supabaseSource: json['supabaseSource'] as String? ?? 'secrets',
      railwayEnvironment: json['railwayEnvironment'] as String?,
      cliFallback: json['cliFallback'] as bool? ?? false,
      syncSupabaseLink: json['syncSupabaseLink'] as bool? ??
          (json['supabaseSource'] as String? ?? 'secrets') != 'supabase_cli',
      supabaseProjectRef: json['supabaseProjectRef'] as String?,
      bindings: bindings,
    );
  }

  Map<String, dynamic> toResolveJson(
    Map<String, TargetDefinition> targets,
    WorkspaceContext ctx,
  ) {
    final targetsJson = <String, dynamic>{};
    for (final entry in bindings.entries) {
      final binding = entry.value;
      targetsJson[entry.key] = {
        if (binding.envFile != null) 'envFile': binding.envFile!.path,
        ...binding.fields,
      };
    }
    for (final entry in targets.entries) {
      if (!entry.value.writeEnvFile && entry.value.secretsFile != null) {
        targetsJson.putIfAbsent(entry.key, () => {});
        (targetsJson[entry.key] as Map<String, dynamic>)['secretsFile'] =
            entry.value.secretsFile!.path;
      }
    }
    return {
      'id': id,
      'description': description,
      'profileId': ctx.profileId,
      'secretsRoot': ctx.profile.secretsRoot,
      'supabaseSource': supabaseSource,
      'railwayEnvironment': railwayEnvironment,
      'targets': targetsJson,
      if (erp != null)
        'erp': {
          'flavor': erp!.flavor,
          'envFile': erp!.envFile?.path,
          'appEnv': erp!.appEnv,
        },
      if (worker != null)
        'worker': {
          'envFile': worker!.envFile?.path,
          'dockerSupabaseUrl': worker!.dockerSupabaseUrl,
        },
      'secretsFile': ctx.secretsFile.path,
      'authFile': ctx.authFile.path,
      'cliFallback': cliFallback,
      'syncSupabaseLink': syncSupabaseLink,
      if (supabaseProjectRef != null) 'supabaseProjectRef': supabaseProjectRef,
    };
  }
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
