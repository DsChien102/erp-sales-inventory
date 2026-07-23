import 'dart:io';

import 'config_init_service.dart';
import 'manifest.dart';

/// Thin alias: `vet45 profile init` → same as `vet45 init <profileId>`.
class ProfileInitService {
  ProfileInitService({
    required this.manifest,
  });

  final EnvManifest manifest;

  Future<void> init(String profileId, {String? description}) async {
    stdout.writeln(
      'Note: prefer `vet45 init $profileId` (profile init is an alias).',
    );
    final service = ConfigInitService(repoRoot: manifest.rootDir);
    final result = await service.init(
      profileId,
      description: description,
    );
    stdout.writeln('Initialized profile: ${result.profileId}');
    stdout.writeln('  secrets: .vet45/profiles/${result.profileId}/');
    for (final path in result.created) {
      stdout.writeln('  created $path');
    }
    if (result.skipped.isNotEmpty) {
      stdout.writeln('  skipped ${result.skipped.length} existing file(s)');
    }
    stdout.writeln('  Active profile set to ${result.profileId}');
    stdout.writeln(
      '  Next: fill .vet45/profiles/${result.profileId}/*.env then: vet45 sync',
    );
  }
}
