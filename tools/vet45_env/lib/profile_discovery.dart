import 'dart:io';

import 'profile_registry.dart';
import 'target_manifest.dart';

/// Discovers configuration profiles by scanning `.vet45/profiles/<id>/`.
class ProfileDiscovery {
  ProfileDiscovery({required this.rootDir});

  final Directory rootDir;

  static const profilesRootName = '.vet45/profiles';
  static const templatesDirName = '.vet45/templates';

  static Directory profilesDir(Directory rootDir) =>
      Directory('${rootDir.path}/$profilesRootName');

  static Directory templatesDir(Directory rootDir) =>
      Directory('${rootDir.path}/$templatesDirName');

  /// Reserved directory names under `.vet45/profiles/` that are never profiles.
  static const reservedNames = {'_templates', 'templates'};

  /// Immediate child dirs of `.vet45/profiles/` that look like profiles.
  Map<String, ProfileDefinition> discover() {
    final profilesRoot = profilesDir(rootDir);
    if (!profilesRoot.existsSync()) {
      return {};
    }

    final profiles = <String, ProfileDefinition>{};
    for (final entity in profilesRoot.listSync(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final name = entity.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull;
      if (name == null || name.isEmpty) {
        continue;
      }
      if (reservedNames.contains(name)) {
        continue;
      }
      // Safety: skip dirs that look like targets.
      if (File('${entity.path}/${TargetManifest.fileName}').existsSync()) {
        continue;
      }
      profiles[name] = ProfileDefinition(
        id: name,
        description: name,
        secretsRoot: '$profilesRootName/$name',
      );
    }
    return profiles;
  }
}
