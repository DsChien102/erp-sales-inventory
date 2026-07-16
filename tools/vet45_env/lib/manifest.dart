import 'dart:io';

import 'profile_registry.dart';
import 'target_discovery.dart';
import 'target_manifest.dart';
import 'workspace_manifest.dart';

export 'repo_root.dart';

/// Composed workspace + discovered targets for sync/doctor/run.
class EnvManifest {
  EnvManifest({
    required this.defaultEnvironmentId,
    required this.targets,
    required this.environments,
    required this.rootDir,
    required this.deploySecretsFile,
    required this.profiles,
    required this.workspace,
  });

  final String defaultEnvironmentId;
  final Map<String, TargetDefinition> targets;
  final Map<String, EnvironmentDefinition> environments;
  final Directory rootDir;
  final File deploySecretsFile;
  final ProfileRegistry profiles;
  final WorkspaceManifest workspace;

  static EnvManifest load(Directory rootDir) {
    final workspace = WorkspaceManifest.load(rootDir);
    final discovered = TargetDiscovery(
      rootDir: rootDir,
      scan: workspace.scan,
    ).discover();

    final targets = <String, TargetDefinition>{};
    for (final entry in discovered.entries) {
      targets[entry.key] = entry.value.toDefinition();
    }

    final environments = <String, EnvironmentDefinition>{};
    for (final envEntry in workspace.environments.entries) {
      final meta = envEntry.value;
      final bindings = <String, TargetBinding>{};
      for (final targetEntry in discovered.entries) {
        final binding = targetEntry.value.bindingFor(meta.id);
        if (binding == null) {
          continue;
        }
        bindings[targetEntry.key] = binding;
      }

      for (final entry in bindings.entries) {
        final target = targets[entry.key]!;
        if (target.writeEnvFile && entry.value.envFile == null) {
          throw StateError(
            'Target "${entry.key}" requires envFile for environment '
            '"${meta.id}" (${discovered[entry.key]!.manifestFile.path})',
          );
        }
      }

      environments[meta.id] = EnvironmentDefinition(
        id: meta.id,
        description: meta.description,
        supabaseSource: meta.supabaseSource,
        railwayEnvironment: meta.railwayEnvironment,
        cliFallback: meta.cliFallback,
        syncSupabaseLink: meta.syncSupabaseLink,
        supabaseProjectRef: meta.supabaseProjectRef,
        bindings: bindings,
      );
    }

    final deployTarget = targets['deploy'];
    final deployFile = deployTarget?.secretsFile ??
        File('${rootDir.path}/config/secrets/deploy.env');

    return EnvManifest(
      defaultEnvironmentId: workspace.defaultEnvironmentId,
      targets: targets,
      environments: environments,
      rootDir: rootDir,
      deploySecretsFile: deployFile,
      profiles: workspace.profiles,
      workspace: workspace,
    );
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
    this.manifestDir,
    this.manifestFile,
    this.kind,
  });

  final String id;
  final String description;
  final List<TargetKeySpec> keys;
  final bool writeEnvFile;

  /// Relative path when this target uses its own secrets file (e.g. deploy).
  final String? secretsFileRelative;
  final File? secretsFile;

  /// Directory containing [vet45.target.json], when discovered.
  final Directory? manifestDir;
  final File? manifestFile;
  final String? kind;

  /// Secrets source for this target (shared deploy file or profile env secrets).
  File secretsSource(WorkspaceContext ctx) => secretsFile ?? ctx.secretsFile;
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
