import 'dart:io';

import 'manifest.dart';
import 'secrets_loader.dart';

/// Resolves hosted Supabase project ref for an environment.
class ProjectRefResolver {
  static const hostedUrlPattern = r'^([a-z0-9]+)\.supabase\.co$';

  /// Manifest `supabaseProjectRef` → secrets `SUPABASE_PROJECT_REF` → `SUPABASE_URL` host.
  static String? resolve(EnvironmentDefinition env, File secretsFile) {
    final manifestRef = env.supabaseProjectRef?.trim() ?? '';
    if (manifestRef.isNotEmpty) {
      return manifestRef;
    }

    if (!secretsFile.existsSync()) {
      return null;
    }

    final secrets = loadDotEnv(secretsFile);
    final secretsRef = secrets['SUPABASE_PROJECT_REF']?.trim() ?? '';
    if (secretsRef.isNotEmpty) {
      return secretsRef;
    }

    final url = secrets['SUPABASE_URL']?.trim() ?? '';
    return parseFromUrl(url);
  }

  static String? parseFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final match = RegExp(
      hostedUrlPattern,
      caseSensitive: false,
    ).firstMatch(uri.host);
    return match?.group(1);
  }

  static bool isHostedUrl(String url) => parseFromUrl(url) != null;
}
