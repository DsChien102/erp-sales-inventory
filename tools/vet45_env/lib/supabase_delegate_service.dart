import 'dart:io';

import 'manifest.dart';
import 'process_runner.dart';
import 'profile_registry.dart';
import 'supabase_context.dart';

/// Runs arbitrary `supabase` CLI commands with active profile credentials.
class SupabaseDelegateService {
  SupabaseDelegateService({
    required this.manifest,
    ProcessRunner? processRunner,
    this.warnWhenTokenMissing = true,
  }) : _process = processRunner ?? IoProcessRunner();

  final EnvManifest manifest;
  final ProcessRunner _process;
  final bool warnWhenTokenMissing;

  Future<int> run(
    WorkspaceContext ctx,
    List<String> supabaseArgs,
  ) async {
    if (supabaseArgs.isEmpty) {
      throw ArgumentError('supabase command requires at least one argument');
    }

    if (warnWhenTokenMissing && !profileHasSupabaseToken(ctx)) {
      stderr.writeln(
        'Warning: no SUPABASE_ACCESS_TOKEN in ${ctx.authFile.path} '
        '(profile ${ctx.profileId}); using global supabase login if any.',
      );
    }

    return _process.run(
      'supabase',
      supabaseArgs,
      workingDirectory: manifest.rootDir.path,
      environment: supabaseProcessEnvironment(ctx),
    );
  }
}
