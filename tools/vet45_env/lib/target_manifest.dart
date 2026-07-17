import 'dart:convert';
import 'dart:io';

import 'action_spec.dart';
import 'manifest.dart';

/// Raw binding fields from a target's per-environment block.
class TargetEnvBindingSpec {
  TargetEnvBindingSpec({
    this.envFileRelative,
    Map<String, String>? fields,
  }) : fields = fields ?? {};

  final String? envFileRelative;
  final Map<String, String> fields;

  factory TargetEnvBindingSpec.fromJson(Map<String, dynamic> json) {
    final fields = <String, String>{};
    String? envFile;
    for (final entry in json.entries) {
      if (entry.key == 'envFile') {
        envFile = entry.value as String?;
        continue;
      }
      final value = entry.value;
      if (value is String) {
        fields[entry.key] = value;
      } else if (value != null) {
        fields[entry.key] = value.toString();
      }
    }
    return TargetEnvBindingSpec(envFileRelative: envFile, fields: fields);
  }
}

/// Parsed [vet45.target.json] colocated with an app/target directory.
class TargetManifest {
  TargetManifest({
    required this.id,
    required this.description,
    required this.keys,
    required this.environmentBindings,
    required this.manifestFile,
    required this.manifestDir,
    this.kind,
    this.writeEnvFile = true,
    this.secretsFileRelative,
    this.secretsFile,
    this.actions = const {},
  });

  final String id;
  final String description;
  final String? kind;
  final List<TargetKeySpec> keys;
  final Map<String, TargetEnvBindingSpec> environmentBindings;
  final File manifestFile;
  final Directory manifestDir;
  final bool writeEnvFile;
  final String? secretsFileRelative;
  final File? secretsFile;
  final Map<String, ActionSpec> actions;

  static const fileName = 'vet45.target.json';

  factory TargetManifest.load(File file) {
    if (!file.existsSync()) {
      throw StateError('Missing target manifest: ${file.path}');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final manifestDir = file.parent;
    final id = json['id'] as String? ?? _deriveId(manifestDir);
    final secretsRelative = json['secretsFile'] as String?;
    final keysJson = json['keys'] as List<dynamic>? ?? [];
    final rawEnvs = json['environments'] as Map<String, dynamic>? ?? {};
    final bindings = <String, TargetEnvBindingSpec>{};
    for (final entry in rawEnvs.entries) {
      bindings[entry.key] = TargetEnvBindingSpec.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    final rawActions = json['actions'] as Map<String, dynamic>? ?? {};
    final actions = <String, ActionSpec>{};
    for (final entry in rawActions.entries) {
      actions[entry.key] = ActionSpec.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return TargetManifest(
      id: id,
      description: json['description'] as String? ?? id,
      kind: json['kind'] as String?,
      writeEnvFile: json['writeEnvFile'] as bool? ?? true,
      secretsFileRelative: secretsRelative,
      secretsFile: secretsRelative == null
          ? null
          : File(resolvePath(manifestDir, secretsRelative)),
      keys: keysJson
          .map((e) => TargetKeySpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      environmentBindings: bindings,
      manifestFile: file,
      manifestDir: manifestDir,
      actions: actions,
    );
  }

  TargetDefinition toDefinition() {
    return TargetDefinition(
      id: id,
      description: description,
      keys: keys,
      writeEnvFile: writeEnvFile,
      secretsFileRelative: secretsFileRelative,
      secretsFile: secretsFile,
      manifestDir: manifestDir,
      manifestFile: manifestFile,
      kind: kind,
      actions: actions,
    );
  }

  TargetBinding? bindingFor(String environmentId) {
    final spec = environmentBindings[environmentId];
    if (spec == null) {
      return null;
    }
    final envFile = spec.envFileRelative == null
        ? null
        : File(resolvePath(manifestDir, spec.envFileRelative!));
    return TargetBinding(
      targetId: id,
      envFile: envFile,
      fields: Map<String, String>.from(spec.fields),
    );
  }

  static String _deriveId(Directory manifestDir) {
    final name = manifestDir.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .lastOrNull;
    if (name == null || name.isEmpty) {
      throw StateError(
        'Cannot derive target id from path: ${manifestDir.path}',
      );
    }
    return name;
  }

  static String resolvePath(Directory base, String relative) {
    return normalizePath('${base.absolute.path}/$relative');
  }

  /// Joins and collapses `.` / `..` segments (without requiring the file to exist).
  static String normalizePath(String path) {
    final isAbsolute = path.startsWith('/') ||
        (path.length >= 3 && path[1] == ':' && (path[2] == '/' || path[2] == '\\'));
    final separator = path.contains('\\') && !path.contains('/') ? '\\' : '/';
    final rawParts = path.replaceAll('\\', '/').split('/');
    final parts = <String>[];
    for (final part in rawParts) {
      if (part.isEmpty || part == '.') {
        continue;
      }
      if (part == '..') {
        if (parts.isNotEmpty && parts.last != '..') {
          parts.removeLast();
        } else if (!isAbsolute) {
          parts.add(part);
        }
        continue;
      }
      parts.add(part);
    }
    if (isAbsolute) {
      if (path.length >= 2 && path[1] == ':') {
        // Windows drive path
        return parts.join(separator);
      }
      return '/${parts.join('/')}';
    }
    return parts.join(separator);
  }
}
