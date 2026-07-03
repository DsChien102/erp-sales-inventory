import 'dart:io';

import 'manifest.dart';
import 'project_ref.dart';
import 'secrets_loader.dart';
import 'supabase_cli.dart';

class LinkResult {
  LinkResult._({
    required this.action,
    this.projectRef,
    this.detail,
  });

  final LinkAction action;
  final String? projectRef;
  final String? detail;

  factory LinkResult.skipped(String reason) =>
      LinkResult._(action: LinkAction.skipped, detail: reason);

  factory LinkResult.alreadyLinked(String projectRef) => LinkResult._(
        action: LinkAction.alreadyLinked,
        projectRef: projectRef,
      );

  factory LinkResult.linked(String projectRef) => LinkResult._(
        action: LinkAction.linked,
        projectRef: projectRef,
      );

  void printSummary() {
    switch (action) {
      case LinkAction.skipped:
        stdout.writeln('Supabase link: skipped${detail == null ? '' : ' ($detail)'}');
      case LinkAction.alreadyLinked:
        stdout.writeln('Supabase link: already linked to $projectRef');
      case LinkAction.linked:
        stdout.writeln('Supabase link: switched to $projectRef');
    }
  }
}

enum LinkAction { skipped, alreadyLinked, linked }

/// Aligns `supabase link` with the active Vet45 environment project ref.
class SupabaseLinkService {
  SupabaseLinkService({
    required this.manifest,
    SupabaseCli? supabaseCli,
  }) : _cli = supabaseCli ?? SupabaseCli(workdir: manifest.rootDir);

  final EnvManifest manifest;
  final SupabaseCli _cli;

  Future<LinkResult> ensureLinked(String environmentId) async {
    final env = manifest.getEnvironment(environmentId);
    if (!env.syncSupabaseLink) {
      return LinkResult.skipped('syncSupabaseLink disabled for ${env.id}');
    }

    final targetRef = ProjectRefResolver.resolve(env);
    if (targetRef == null) {
      return LinkResult.skipped(
        'no hosted project ref (set supabaseProjectRef or SUPABASE_URL in secrets)',
      );
    }

    final currentRef = SupabaseCli.readLinkedProjectRef(manifest.rootDir);
    if (currentRef == targetRef) {
      return LinkResult.alreadyLinked(targetRef);
    }

    final dbPassword = _readDbPassword(env);
    await _cli.linkProject(projectRef: targetRef, dbPassword: dbPassword);
    return LinkResult.linked(targetRef);
  }

  String? _readDbPassword(EnvironmentDefinition env) {
    if (!env.secretsFile.existsSync()) {
      return null;
    }
    final secrets = loadDotEnv(env.secretsFile);
    final password = secrets['SUPABASE_DB_PASSWORD']?.trim() ?? '';
    return password.isEmpty ? null : password;
  }
}
