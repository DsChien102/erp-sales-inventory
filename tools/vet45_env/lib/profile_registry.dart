import 'dart:convert';
import 'dart:io';

import 'manifest.dart';
import 'profile_discovery.dart';
import 'secrets_loader.dart';

/// Configuration profile (Supabase workspace / client secrets bundle).
class ProfileDefinition {
  ProfileDefinition({
    required this.id,
    required this.description,
    required this.secretsRoot,
  });

  final String id;
  final String description;

  /// Directory containing `<environment>.env` and optional `auth.env`.
  /// Convention: `.vet45/profiles/<profileId>/`.
  final String secretsRoot;

  Directory secretsDirectory(Directory repoRoot) =>
      Directory('${repoRoot.path}/$secretsRoot');

  File secretsFileFor(Directory repoRoot, String environmentId) =>
      File('${repoRoot.path}/$secretsRoot/$environmentId.env');

  File authFile(Directory repoRoot) =>
      File('${repoRoot.path}/$secretsRoot/auth.env');

  File authExampleFile(Directory repoRoot) =>
      File('${repoRoot.path}/$secretsRoot/auth.env.example');
}

/// Discovered profiles under `.vet45/profiles/<id>/` (in-memory, not in workspace JSON).
class ProfileRegistry {
  ProfileRegistry({
    required this.profiles,
    required this.rootDir,
  });

  final Map<String, ProfileDefinition> profiles;
  final Directory rootDir;

  factory ProfileRegistry.discover(Directory rootDir) {
    return ProfileRegistry(
      profiles: ProfileDiscovery(rootDir: rootDir).discover(),
      rootDir: rootDir,
    );
  }

  bool get isEmpty => profiles.isEmpty;

  ProfileDefinition getProfile(String id) {
    final profile = profiles[id];
    if (profile == null) {
      throw ArgumentError(
        'Unknown profile: $id\n'
        'Run: vet45 init $id   # or vet45 list to see existing profiles',
      );
    }
    return profile;
  }

  ProfileDefinition resolve(String id) => getProfile(id);
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

/// Reads active profile/environment from `.vet45/state.json`.
///
/// Profile is required (no workspace default). Environment falls back to
/// [defaultEnvironmentId] when missing from state.
ActiveState readActiveState(
  Directory rootDir, {
  required String defaultEnvironmentId,
  Set<String>? knownProfileIds,
}) {
  final stateFile = _stateFile(rootDir);
  if (!stateFile.existsSync()) {
    throw StateError(
      'No active profile. First-time setup:\n'
      '  vet45 init <profileId>\n'
      'Then fill .vet45/profiles/<profileId>/*.env and run: vet45 sync',
    );
  }

  late final Map<String, dynamic> json;
  try {
    json = jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
  } on Object {
    throw StateError(
      'Corrupt .vet45/state.json. Re-run: vet45 init <profileId>',
    );
  }

  final profile = (json['profile'] as String?)?.trim() ?? '';
  if (profile.isEmpty) {
    throw StateError(
      'No active profile in .vet45/state.json.\n'
      'Run: vet45 init <profileId>',
    );
  }

  if (knownProfileIds != null && !knownProfileIds.contains(profile)) {
    throw StateError(
      'Active profile "$profile" not found under .vet45/profiles/.\n'
      'Run: vet45 init $profile   # or vet45 switch <existingProfile>',
    );
  }

  final environment =
      (json['environment'] as String?)?.trim().isNotEmpty == true
          ? json['environment'] as String
          : (readActive(rootDir) ?? defaultEnvironmentId);

  return ActiveState(profileId: profile, environmentId: environment);
}

/// Best-effort read that returns null when no valid active profile exists.
ActiveState? tryReadActiveState(
  Directory rootDir, {
  required String defaultEnvironmentId,
  Set<String>? knownProfileIds,
}) {
  try {
    return readActiveState(
      rootDir,
      defaultEnvironmentId: defaultEnvironmentId,
      knownProfileIds: knownProfileIds,
    );
  } on StateError {
    return null;
  }
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
    final known = manifest.profiles.profiles.keys.toSet();
    late final String resolvedProfileId;
    late final String resolvedEnvironmentId;

    if (profileId != null) {
      resolvedProfileId = profileId;
      final existing = tryReadActiveState(
        manifest.rootDir,
        defaultEnvironmentId: manifest.defaultEnvironmentId,
        knownProfileIds: known,
      );
      resolvedEnvironmentId = environmentId ??
          existing?.environmentId ??
          manifest.defaultEnvironmentId;
    } else {
      final state = readActiveState(
        manifest.rootDir,
        defaultEnvironmentId: manifest.defaultEnvironmentId,
        knownProfileIds: known,
      );
      resolvedProfileId = state.profileId;
      resolvedEnvironmentId = environmentId ?? state.environmentId;
    }

    final resolvedProfile = manifest.profiles.resolve(resolvedProfileId);
    final resolvedEnv = manifest.getEnvironment(resolvedEnvironmentId);
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
