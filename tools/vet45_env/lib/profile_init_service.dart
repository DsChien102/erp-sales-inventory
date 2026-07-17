import 'dart:io';

import 'manifest.dart';
import 'profile_registry.dart';
import 'workspace_manifest.dart';

/// Scaffold a new configuration profile under `config/<profileId>/`.
class ProfileInitService {
  ProfileInitService({
    required this.manifest,
  });

  final EnvManifest manifest;

  static const _authExample = '''
# Supabase CLI access token for this profile.
# Create at https://supabase.com/dashboard/account/tokens
# Required for supabase link when switching profiles/accounts.
SUPABASE_ACCESS_TOKEN=
''';

  Future<void> init(String profileId, {String? description}) async {
    if (manifest.profiles.profiles.containsKey(profileId)) {
      throw StateError('Profile already exists: $profileId');
    }
    if (profileId == manifest.profiles.defaultProfileId) {
      throw StateError(
        'Cannot init reserved profile id: ${manifest.profiles.defaultProfileId}',
      );
    }
    if (_isReservedTargetId(profileId)) {
      throw StateError('Cannot init reserved target/config id: $profileId');
    }

    final secretsRoot = 'config/$profileId';
    final profileDir = Directory('${manifest.rootDir.path}/$secretsRoot');
    profileDir.createSync(recursive: true);

    _writeWorkspaceProfileEntry(profileId, description, secretsRoot);

    final defaultProfile = manifest.profiles.getProfile(
      manifest.profiles.defaultProfileId,
    );
    final defaultRoot = defaultProfile.secretsDirectory(manifest.rootDir);
    for (final envId in manifest.environments.keys) {
      final exampleName = '$envId.env.example';
      final source = File('${defaultRoot.path}/$exampleName');
      final dest = File('${profileDir.path}/$exampleName');
      if (source.existsSync()) {
        dest.writeAsStringSync(source.readAsStringSync());
      } else {
        dest.writeAsStringSync(
          '# $envId secrets for profile $profileId\n'
          'SUPABASE_URL=\n'
          'SUPABASE_ANON_KEY=\n'
          'SUPABASE_SERVICE_ROLE_KEY=\n',
        );
      }
    }

    File('${profileDir.path}/auth.env.example')
        .writeAsStringSync(_authExample.trim());

    stdout.writeln('Initialized profile: $profileId');
    stdout.writeln('  secrets: ${profileDir.path}');
    stdout.writeln(
      '  registry: ${WorkspaceManifest.workspaceFile(manifest.rootDir).path}',
    );
    stdout.writeln(
      '  Next: cp ${profileDir.path}/*.env.example to *.env and fill keys',
    );
    stdout.writeln('  Then: vet45 switch $profileId');
  }

  void _writeWorkspaceProfileEntry(
    String profileId,
    String? description,
    String secretsRoot,
  ) {
    final workspace = WorkspaceManifest.load(manifest.rootDir);
    final updatedProfiles = Map<String, ProfileDefinition>.from(
      workspace.profiles.profiles,
    );
    updatedProfiles[profileId] = ProfileDefinition(
      id: profileId,
      description: description ?? profileId,
      secretsRoot: secretsRoot,
    );

    final updated = WorkspaceManifest(
      version: workspace.version,
      defaultEnvironmentId: workspace.defaultEnvironmentId,
      scan: workspace.scan,
      profiles: ProfileRegistry(
        defaultProfileId: workspace.profiles.defaultProfileId,
        profiles: updatedProfiles,
        rootDir: workspace.rootDir,
      ),
      environments: workspace.environments,
      rootDir: workspace.rootDir,
      file: workspace.file,
      doctor: workspace.doctor,
    );
    updated.write();
  }

  bool _isReservedTargetId(String profileId) {
    final target = manifest.targets[profileId];
    return target != null && !target.writeEnvFile;
  }
}
