import 'manifest.dart';

/// Missing required keys for a single target.
class TargetKeyError implements Exception {
  TargetKeyError({
    required this.targetId,
    required this.missingKeys,
  });

  final String targetId;
  final List<String> missingKeys;

  @override
  String toString() =>
      'Target "$targetId" missing required keys: ${missingKeys.join(', ')}';
}

/// Resolves output env values for a target from canonical secrets + binding.
class KeyResolver {
  KeyResolver._();

  static Map<String, String> resolve({
    required TargetDefinition target,
    required TargetBinding? binding,
    required Map<String, String> canonical,
  }) {
    final missing = <String>[];
    final result = <String, String>{};

    for (final key in target.keys) {
      if (key.fromManifest != null) {
        final field = key.fromManifest!;
        final value = binding?.fields[field]?.trim() ?? '';
        if (value.isNotEmpty) {
          result[key.name] = value;
        } else if (key.defaultValue != null) {
          result[key.name] = key.defaultValue!;
        } else if (key.required || key.fromManifest != null) {
          // fromManifest without a value is always required for that field.
          missing.add('${key.name} (manifest.$field)');
        }
        continue;
      }

      final sourceKey = key.sourceKey;
      final raw = canonical[sourceKey]?.trim() ?? '';
      if (raw.isNotEmpty) {
        result[key.name] = raw;
      } else if (key.defaultValue != null) {
        result[key.name] = key.defaultValue!;
      } else if (key.required) {
        missing.add(sourceKey == key.name ? key.name : '${key.name} (from $sourceKey)');
      }
    }

    if (missing.isNotEmpty) {
      throw TargetKeyError(targetId: target.id, missingKeys: missing);
    }
    return result;
  }

  /// Validates required keys exist in [values] (generated env or secrets file).
  static List<String> missingRequired({
    required TargetDefinition target,
    required Map<String, String> values,
  }) {
    final missing = <String>[];
    for (final key in target.keys) {
      if (!key.required && key.fromManifest == null) {
        continue;
      }
      if (key.fromManifest != null && !key.required) {
        // Manifest fields are always present after a successful sync write.
        final value = values[key.name]?.trim() ?? '';
        if (value.isEmpty) {
          missing.add(key.name);
        }
        continue;
      }
      if (!key.required) {
        continue;
      }
      final value = values[key.name]?.trim() ?? '';
      if (value.isEmpty) {
        missing.add(key.name);
      }
    }
    return missing;
  }
}
