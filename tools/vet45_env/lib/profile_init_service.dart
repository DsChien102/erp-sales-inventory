import 'dart:convert';
import 'dart:io';

import 'manifest.dart';
import 'profile_registry.dart';
import 'secrets_loader.dart';

/// Scaffold a new configuration profile.
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
    if (profileId == 'default') {
      throw StateError('Cannot init reserved profile id: default');
    }

    final secretsRoot = 'config/profiles/$profileId/secrets';
    final profileDir = Directory('${manifest.rootDir.path}/$secretsRoot');
    profileDir.createSync(recursive: true);

    _writeProfileRegistryEntry(profileId, description, secretsRoot);

    for (final envId in manifest.environments.keys) {
      final exampleName = '$envId.env.example';
      final source = File(
        '${manifest.rootDir.path}/config/secrets/$exampleName',
      );
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
    stdout.writeln('  Next: cp ${profileDir.path}/*.env.example to *.env and fill keys');
    stdout.writeln('  Then: melos run profile:use -- $profileId');
  }

  void _writeProfileRegistryEntry(
    String profileId,
    String? description,
    String secretsRoot,
  ) {
    final registryFile = File('${manifest.rootDir.path}/config/profiles.json');
    final registry = ProfileRegistry.load(manifest.rootDir);
    final updated = {
      'defaultProfile': registry.defaultProfileId,
      'profiles': {
        for (final entry in registry.profiles.entries)
          entry.key: {
            'description': entry.value.description,
            'secretsRoot': entry.value.secretsRoot,
          },
        profileId: {
          'description': description ?? profileId,
          'secretsRoot': secretsRoot,
        },
      },
    };
    registryFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(updated)}\n',
    );
  }
}
