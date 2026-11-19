import 'dart:io';

import 'target_discovery.dart';
import 'target_manifest.dart';
import 'workspace_manifest.dart';

/// One ownership line for a canonical secrets key.
class ExampleKeyOwner {
  const ExampleKeyOwner({
    required this.targetId,
    required this.description,
    this.defaultValue,
  });

  final String targetId;
  final String description;
  final String? defaultValue;
}

/// Aggregated secrets key for `.env.example` (canonical [sourceKey]).
class ExampleKeyEntry {
  ExampleKeyEntry({
    required this.sourceKey,
    required this.owners,
  });

  final String sourceKey;
  final List<ExampleKeyOwner> owners;

  String? get preferredDefault {
    for (final owner in owners) {
      final value = owner.defaultValue;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class ExampleWriteResult {
  ExampleWriteResult({required this.created, required this.skipped});

  final List<String> created;
  final List<String> skipped;
}

/// Generates `.env.example` content from discovered [c45.target.json] keys.
///
/// Comment format: `# <targetId>: <description>`
class ExampleGenerator {
  ExampleGenerator({
    required this.repoRoot,
    WorkspaceManifest? workspace,
    Map<String, TargetManifest>? targets,
  }) : workspace = workspace ?? WorkspaceManifest.load(repoRoot),
       targets =
           targets ??
           TargetDiscovery(
             rootDir: repoRoot,
             scan: (workspace ?? WorkspaceManifest.load(repoRoot)).scan,
           ).discover();

  final Directory repoRoot;
  final WorkspaceManifest workspace;
  final Map<String, TargetManifest> targets;

  /// Profile-only helpers used by `c45 link` (not declared on app targets).
  static const profileLinkKeys = <(String, String)>[
    (
      'SUPABASE_PROJECT_REF',
      'Optional project ref; derived from SUPABASE_URL if omitted',
    ),
    (
      'SUPABASE_DB_PASSWORD',
      'Optional DB password for supabase link',
    ),
  ];

  static const authExampleBody =
      '# Auth (profile) — optional Supabase CLI access token\n'
      '# Create at https://supabase.com/dashboard/account/tokens\n'
      '# Used by c45 for supabase link when switching accounts.\n'
      'SUPABASE_ACCESS_TOKEN=\n';

  /// Validate every non-`fromManifest` key has a non-empty description.
  List<String> missingDescriptions() {
    final missing = <String>[];
    for (final target in targets.values) {
      for (final key in target.keys) {
        if (key.isManifestDerived) {
          continue;
        }
        final desc = key.description?.trim() ?? '';
        if (desc.isEmpty) {
          missing.add('${target.id}.${key.name}');
        }
      }
    }
    return missing;
  }

  void ensureDescriptionsPresent() {
    final missing = missingDescriptions();
    if (missing.isEmpty) {
      return;
    }
    throw StateError(
      'Missing key description(s) in c45.target.json:\n'
      '${missing.map((e) => '  - $e').join('\n')}\n'
      'Add "description" for each secrets key (skip fromManifest keys).',
    );
  }

  /// Profile aggregate keys from targets with [writeEnvFile] == true.
  List<ExampleKeyEntry> collectProfileEntries() {
    final bySource = <String, List<ExampleKeyOwner>>{};
    for (final target in targets.values) {
      if (!target.writeEnvFile) {
        continue;
      }
      for (final key in target.keys) {
        if (key.isManifestDerived) {
          continue;
        }
        final desc = key.description?.trim() ?? '';
        if (desc.isEmpty) {
          continue;
        }
        bySource
            .putIfAbsent(key.sourceKey, () => <ExampleKeyOwner>[])
            .add(
              ExampleKeyOwner(
                targetId: target.id,
                description: desc,
                defaultValue: key.defaultValue,
              ),
            );
      }
    }

    final entries =
        bySource.entries.map((e) {
          final owners = List<ExampleKeyOwner>.from(e.value)
            ..sort((a, b) => a.targetId.compareTo(b.targetId));
          return ExampleKeyEntry(
            sourceKey: e.key,
            owners: List<ExampleKeyOwner>.unmodifiable(owners),
          );
        }).toList()..sort((a, b) => a.sourceKey.compareTo(b.sourceKey));
    return entries;
  }

  List<ExampleKeyEntry> collectDeployEntries() {
    final deploy = targets['deploy'];
    if (deploy == null) {
      return const [];
    }
    final entries = <ExampleKeyEntry>[];
    for (final key in deploy.keys) {
      if (key.isManifestDerived) {
        continue;
      }
      final desc = key.description?.trim() ?? '';
      if (desc.isEmpty) {
        continue;
      }
      entries.add(
        ExampleKeyEntry(
          sourceKey: key.sourceKey,
          owners: [
            ExampleKeyOwner(
              targetId: deploy.id,
              description: desc,
              defaultValue: key.defaultValue,
            ),
          ],
        ),
      );
    }
    entries.sort((a, b) => a.sourceKey.compareTo(b.sourceKey));
    return entries;
  }

  String renderProfileExample({required String environmentId}) {
    ensureDescriptionsPresent();
    final buffer = StringBuffer();
    buffer.writeln(_profileHeader(environmentId));
    buffer.writeln();

    for (final entry in collectProfileEntries()) {
      _writeEntry(buffer, entry, commentOutValues: environmentId == 'local');
      buffer.writeln();
    }

    for (final (name, description) in profileLinkKeys) {
      buffer.writeln('# profile: $description');
      if (environmentId == 'local') {
        buffer.writeln('# $name=');
      } else {
        buffer.writeln('$name=');
      }
      buffer.writeln();
    }

    return '${buffer.toString().trimRight()}\n';
  }

  String renderAuthExample() => authExampleBody;

  String renderDeployExample() {
    ensureDescriptionsPresent();
    final buffer = StringBuffer();
    buffer.writeln(
      '# Shared deploy secrets (iOS TestFlight / App Store Connect).',
    );
    buffer.writeln('# Generated from deploy/c45.target.json');
    buffer.writeln();
    for (final entry in collectDeployEntries()) {
      _writeEntry(buffer, entry, commentOutValues: false);
      buffer.writeln();
    }
    return '${buffer.toString().trimRight()}\n';
  }

  /// Writes profile `<env>.env.example` (+ empty `.env` when allowed), auth, deploy.
  ///
  /// [forceExamples] refreshes `*.env.example` even if present.
  /// Filled secret `.env` files are never overwritten.
  ExampleWriteResult writeExamples({
    required Directory profileDir,
    required String relativeProfilePrefix,
    bool force = false,
    bool forceExamples = true,
    bool writeEnvCopies = true,
  }) {
    ensureDescriptionsPresent();
    final created = <String>[];
    final skipped = <String>[];

    profileDir.createSync(recursive: true);

    for (final envId in workspace.environments.keys) {
      final exampleName = '$envId.env.example';
      final exampleFile = File('${profileDir.path}/$exampleName');
      final content = renderProfileExample(environmentId: envId);
      _writeGeneratedFile(
        exampleFile,
        content: content,
        relative: '$relativeProfilePrefix/$exampleName',
        force: force || forceExamples,
        created: created,
        skipped: skipped,
        treatAsSecretEnv: false,
      );

      if (writeEnvCopies) {
        final envName = '$envId.env';
        final envFile = File('${profileDir.path}/$envName');
        _writeGeneratedFile(
          envFile,
          content: content,
          relative: '$relativeProfilePrefix/$envName',
          force: force,
          created: created,
          skipped: skipped,
          treatAsSecretEnv: true,
        );
      }
    }

    final authExample = File('${profileDir.path}/auth.env.example');
    _writeGeneratedFile(
      authExample,
      content: renderAuthExample(),
      relative: '$relativeProfilePrefix/auth.env.example',
      force: force || forceExamples,
      created: created,
      skipped: skipped,
      treatAsSecretEnv: false,
    );
    if (writeEnvCopies) {
      _writeGeneratedFile(
        File('${profileDir.path}/auth.env'),
        content: renderAuthExample(),
        relative: '$relativeProfilePrefix/auth.env',
        force: force,
        created: created,
        skipped: skipped,
        treatAsSecretEnv: true,
      );
    }

    final deployTarget = targets['deploy'];
    if (deployTarget != null && deployTarget.secretsFile != null) {
      final deployDir = deployTarget.manifestDir;
      final exampleFile = File('${deployDir.path}/deploy.env.example');
      final envFile = File('${deployDir.path}/deploy.env');
      final relDir = _relativePath(repoRoot, deployDir.path);
      final content = renderDeployExample();
      _writeGeneratedFile(
        exampleFile,
        content: content,
        relative: '$relDir/deploy.env.example',
        force: force || forceExamples,
        created: created,
        skipped: skipped,
        treatAsSecretEnv: false,
      );
      if (writeEnvCopies) {
        _writeGeneratedFile(
          envFile,
          content: content,
          relative: '$relDir/deploy.env',
          force: force,
          created: created,
          skipped: skipped,
          treatAsSecretEnv: true,
        );
      }
    }

    return ExampleWriteResult(created: created, skipped: skipped);
  }

  static String _profileHeader(String environmentId) {
    return switch (environmentId) {
      'local' =>
        '# Local overrides (optional). CLI may fill Supabase from `supabase status`.\n'
            '# Lines are commented by default — uncomment to override.',
      'development' =>
        '# Development secrets (remote). Fill values then: c45 sync',
      'staging' => '# Staging secrets (remote). Fill values then: c45 sync',
      'production' =>
        '# Production secrets (remote). Fill values then: c45 sync',
      _ =>
        '# Secrets for environment `$environmentId`. Fill values then: c45 sync',
    };
  }

  static void _writeEntry(
    StringBuffer buffer,
    ExampleKeyEntry entry, {
    required bool commentOutValues,
  }) {
    for (final owner in entry.owners) {
      buffer.writeln('# ${owner.targetId}: ${owner.description}');
    }
    final value = entry.preferredDefault ?? '';
    final line = '${entry.sourceKey}=$value';
    if (commentOutValues) {
      buffer.writeln('# $line');
    } else {
      buffer.writeln(line);
    }
  }

  static void _writeGeneratedFile(
    File file, {
    required String content,
    required String relative,
    required bool force,
    required List<String> created,
    required List<String> skipped,
    required bool treatAsSecretEnv,
  }) {
    if (file.existsSync()) {
      if (treatAsSecretEnv && _isFilledSecretEnv(file)) {
        skipped.add(relative);
        return;
      }
      if (!force) {
        skipped.add(relative);
        return;
      }
      if (treatAsSecretEnv && _isFilledSecretEnv(file)) {
        skipped.add(relative);
        return;
      }
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    created.add(relative);
  }
}

bool _isFilledSecretEnv(File file) {
  final path = file.path;
  if (!path.endsWith('.env') || path.endsWith('.env.example')) {
    return false;
  }
  if (!file.existsSync()) {
    return false;
  }
  final content = file.readAsStringSync().trim();
  if (content.isEmpty) {
    return false;
  }
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final eq = trimmed.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final value = trimmed.substring(eq + 1).trim();
    if (value.isNotEmpty) {
      return true;
    }
  }
  return false;
}

String _relativePath(Directory root, String absolutePath) {
  final rootPath = root.path.endsWith(Platform.pathSeparator)
      ? root.path
      : '${root.path}${Platform.pathSeparator}';
  if (absolutePath.startsWith(rootPath)) {
    return absolutePath.substring(rootPath.length).replaceAll('\\', '/');
  }
  return absolutePath.replaceAll('\\', '/');
}
