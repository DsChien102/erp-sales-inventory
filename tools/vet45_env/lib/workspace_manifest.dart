import 'dart:convert';
import 'dart:io';

/// Host alignment rule from [vet45.workspace.json] `doctor.alignHosts`.
class DoctorAlignHostRule {
  const DoctorAlignHostRule({
    required this.name,
    required this.targets,
    required this.keys,
  });

  final String name;
  final List<String> targets;
  final List<String> keys;

  factory DoctorAlignHostRule.fromJson(Map<String, dynamic> json) {
    return DoctorAlignHostRule(
      name: json['name'] as String? ?? 'host alignment',
      targets: (json['targets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      keys: (json['keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Doctor configuration from workspace manifest.
class DoctorConfig {
  const DoctorConfig({this.alignHosts = const []});

  final List<DoctorAlignHostRule> alignHosts;

  factory DoctorConfig.fromJson(Map<String, dynamic>? json) {
    final raw = json?['alignHosts'] as List<dynamic>? ?? [];
    return DoctorConfig(
      alignHosts: raw
          .map(
            (e) => DoctorAlignHostRule.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// Scan policy for discovering [vet45.target.json] files.
class ScanPolicy {
  ScanPolicy({
    required this.include,
    required this.exclude,
  });

  final List<String> include;
  final List<String> exclude;

  factory ScanPolicy.fromJson(Map<String, dynamic>? json) {
    final include = (json?['include'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        ['apps/**/vet45.target.json', 'packages/**/vet45.target.json', '.vet45/**/vet45.target.json'];
    final exclude = (json?['exclude'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        ['**/.dart_tool/**', '**/build/**'];
    return ScanPolicy(include: include, exclude: exclude);
  }
}

/// Environment metadata from [vet45.workspace.json] (no target bindings).
class WorkspaceEnvironmentMeta {
  WorkspaceEnvironmentMeta({
    required this.id,
    required this.description,
    required this.supabaseSource,
    this.railwayEnvironment,
    this.cliFallback = false,
    this.syncSupabaseLink = true,
    this.supabaseProjectRef,
  });

  final String id;
  final String description;
  final String supabaseSource;
  final String? railwayEnvironment;
  final bool cliFallback;
  final bool syncSupabaseLink;
  final String? supabaseProjectRef;

  factory WorkspaceEnvironmentMeta.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    final source = json['supabaseSource'] as String? ?? 'secrets';
    return WorkspaceEnvironmentMeta(
      id: id,
      description: json['description'] as String? ?? id,
      supabaseSource: source,
      railwayEnvironment: json['railwayEnvironment'] as String?,
      cliFallback: json['cliFallback'] as bool? ?? false,
      syncSupabaseLink: json['syncSupabaseLink'] as bool? ??
          source != 'supabase_cli',
      supabaseProjectRef: json['supabaseProjectRef'] as String?,
    );
  }
}

/// Loaded [vet45.workspace.json] — environments, scan policy, doctor rules.
/// Profiles are discovered from `.vet45/profiles/<id>/`, not declared here.
class WorkspaceManifest {
  WorkspaceManifest({
    required this.version,
    required this.defaultEnvironmentId,
    required this.scan,
    required this.environments,
    required this.rootDir,
    required this.file,
    this.doctor = const DoctorConfig(),
  });

  final int version;
  final String defaultEnvironmentId;
  final ScanPolicy scan;
  final Map<String, WorkspaceEnvironmentMeta> environments;
  final Directory rootDir;
  final File file;
  final DoctorConfig doctor;

  static const fileName = 'vet45.workspace.json';

  static File workspaceFile(Directory rootDir) =>
      File('${rootDir.path}/$fileName');

  static WorkspaceManifest load(Directory rootDir) {
    final file = workspaceFile(rootDir);
    if (!file.existsSync()) {
      throw StateError(
        'Missing workspace manifest: ${file.path}\n'
        'Expected committed $fileName at the Vet45 repo root.',
      );
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final version = json['version'] as int? ?? 1;
    final defaultId = json['defaultEnvironment'] as String? ??
        json['default'] as String? ??
        'development';

    final scan = ScanPolicy.fromJson(json['scan'] as Map<String, dynamic>?);
    final doctor = DoctorConfig.fromJson(json['doctor'] as Map<String, dynamic>?);

    final rawEnvs = json['environments'] as Map<String, dynamic>? ?? {};
    final environments = <String, WorkspaceEnvironmentMeta>{};
    for (final entry in rawEnvs.entries) {
      environments[entry.key] = WorkspaceEnvironmentMeta.fromJson(
        id: entry.key,
        json: entry.value as Map<String, dynamic>,
      );
    }
    if (environments.isEmpty) {
      throw StateError('$fileName has no environments');
    }
    if (!environments.containsKey(defaultId)) {
      throw StateError(
        'default environment "$defaultId" not found in $fileName',
      );
    }

    return WorkspaceManifest(
      version: version,
      defaultEnvironmentId: defaultId,
      scan: scan,
      environments: environments,
      rootDir: rootDir,
      file: file,
      doctor: doctor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'defaultEnvironment': defaultEnvironmentId,
      'scan': {
        'include': scan.include,
        'exclude': scan.exclude,
      },
      'environments': {
        for (final entry in environments.entries)
          entry.key: {
            'description': entry.value.description,
            'supabaseSource': entry.value.supabaseSource,
            if (entry.value.railwayEnvironment != null)
              'railwayEnvironment': entry.value.railwayEnvironment,
            if (entry.value.cliFallback) 'cliFallback': true,
            if (!entry.value.syncSupabaseLink) 'syncSupabaseLink': false,
            if (entry.value.supabaseProjectRef != null)
              'supabaseProjectRef': entry.value.supabaseProjectRef,
          },
      },
      if (doctor.alignHosts.isNotEmpty)
        'doctor': {
          'alignHosts': [
            for (final rule in doctor.alignHosts)
              {
                'name': rule.name,
                'targets': rule.targets,
                'keys': rule.keys,
              },
          ],
        },
    };
  }

  void write() {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n',
    );
  }
}
