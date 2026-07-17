import 'dart:convert';
import 'dart:io';

import 'manifest.dart';
import 'secrets_loader.dart';

/// Registered configuration profile (Supabase workspace / client).
class ProfileDefinition {
  ProfileDefinition({
    required this.id,
    required this.description,
    required this.secretsRoot,
  });

  final String id;
  final String description;

  /// Directory containing `<environment>.env` and optional `auth.env`.
  /// Convention: `config/<profileId>/`.
  final String secretsRoot;

  factory ProfileDefinition.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    final root = json['secretsRoot'] as String? ?? 'config/$id';
    return ProfileDefinition(
      id: id,
      description: json['description'] as String? ?? id,
      secretsRoot: root,
    );
  }

  Directory secretsDirectory(Directory repoRoot) =>
      Directory('${repoRoot.path}/$secretsRoot');

  File secretsFileFor(Directory repoRoot, String environmentId) =>
      File('${repoRoot.path}/$secretsRoot/$environmentId.env');

  File authFile(Directory repoRoot) =>
      File('${repoRoot.path}/$secretsRoot/auth.env');

  File authExampleFile(Directory repoRoot) =>
      File('${repoRoot.path}/$secretsRoot/auth.env.example');
}

/// Profiles section from [vet45.workspace.json].
class ProfileRegistry {
  ProfileRegistry({
    required this.defaultProfileId,
    required this.profiles,
    required this.rootDir,
  });

  final String defaultProfileId;
  final Map<String, ProfileDefinition> profiles;
  final Directory rootDir;

  /// Load profiles from the committed workspace manifest.
  factory ProfileRegistry.fromWorkspaceJson({
    required Directory rootDir,
    required Map<String, dynamic>? json,
  }) {
    if (json == null) {
      return ProfileRegistry(
        defaultProfileId: 'default',
        profiles: {
          'default': ProfileDefinition(
            id: 'default',
            description: 'Vet45 main',
            secretsRoot: 'config/default',
          ),
        },
        rootDir: rootDir,
      );
    }

    final defaultId = json['defaultProfile'] as String? ?? 'default';
    final raw = json['entries'] as Map<String, dynamic>? ??
        json['profiles'] as Map<String, dynamic>? ??
        {};
    final profiles = <String, ProfileDefinition>{};
    for (final entry in raw.entries) {
      profiles[entry.key] = ProfileDefinition.fromJson(
        id: entry.key,
        json: entry.value as Map<String, dynamic>,
      );
    }
    if (profiles.isEmpty) {
      throw StateError('vet45.workspace.json has no profiles');
    }
    if (!profiles.containsKey(defaultId)) {
      throw StateError(
        'default profile "$defaultId" not found in vet45.workspace.json',
      );
    }
    return ProfileRegistry(
      defaultProfileId: defaultId,
      profiles: profiles,
      rootDir: rootDir,
    );
  }

  ProfileDefinition getProfile(String id) {
    final profile = profiles[id];
    if (profile == null) {
      throw ArgumentError('Unknown profile: $id');
    }
    return profile;
  }

  ProfileDefinition resolve(String? id) =>
      getProfile(id ?? defaultProfileId);
}

/// Active profile + environment selection.
class ActiveState {
  ActiveState({
    required this.profileId,
    required this.environmentId,
  });

  final String profileId;
  final String environmentId;
}

File _stateFile(Directory rootDir) => File('${rootDir.path}/.vet45/state.json');

ActiveState readActiveState(
  Directory rootDir, {
  required String defaultProfileId,
  required String defaultEnvironmentId,
}) {
  final stateFile = _stateFile(rootDir);
  if (stateFile.existsSync()) {
    try {
      final json =
          jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
      final profile = json['profile'] as String? ?? defaultProfileId;
      final environment = json['environment'] as String? ?? defaultEnvironmentId;
      return ActiveState(profileId: profile, environmentId: environment);
    } on Object {
      // fall through to legacy
    }
  }
  final legacyEnv = readActive(rootDir);
  return ActiveState(
    profileId: defaultProfileId,
    environmentId: legacyEnv ?? defaultEnvironmentId,
  );
}

void writeActiveState(Directory rootDir, ActiveState state) {
  final dir = Directory('${rootDir.path}/.vet45');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  _stateFile(rootDir).writeAsStringSync(
    '${jsonEncode({'profile': state.profileId, 'environment': state.environmentId})}\n',
  );
  writeActive(rootDir, state.environmentId);
}

/// Resolved profile + environment for sync/link/run.
class WorkspaceContext {
  WorkspaceContext({
    required this.profile,
    required this.environment,
    required this.secretsFile,
    required this.authFile,
  });

  final ProfileDefinition profile;
  final EnvironmentDefinition environment;
  final File secretsFile;
  final File authFile;

  String get profileId => profile.id;
  String get environmentId => environment.id;

  factory WorkspaceContext.resolve({
    required EnvManifest manifest,
    String? profileId,
    String? environmentId,
  }) {
    final state = readActiveState(
      manifest.rootDir,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    final resolvedProfile = manifest.profiles.resolve(profileId ?? state.profileId);
    final resolvedEnv = manifest.getEnvironment(
      environmentId ?? state.environmentId,
    );
    return WorkspaceContext(
      profile: resolvedProfile,
      environment: resolvedEnv,
      secretsFile: resolvedProfile.secretsFileFor(
        manifest.rootDir,
        resolvedEnv.id,
      ),
      authFile: resolvedProfile.authFile(manifest.rootDir),
    );
  }
}

/// Reads Supabase CLI token for the active profile (`auth.env` then env secrets).
Map<String, String> loadProfileAuthEnvironment(WorkspaceContext ctx) {
  final merged = <String, String>{};
  if (ctx.authFile.existsSync()) {
    merged.addAll(loadDotEnv(ctx.authFile));
  }
  if (ctx.secretsFile.existsSync()) {
    merged.addAll(loadDotEnv(ctx.secretsFile));
  }
  final token = merged['SUPABASE_ACCESS_TOKEN']?.trim() ?? '';
  if (token.isEmpty) {
    return {};
  }
  return {'SUPABASE_ACCESS_TOKEN': token};
}
