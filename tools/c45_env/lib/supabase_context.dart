import 'dart:io';

import 'manifest.dart';
import 'profile_registry.dart';
import 'supabase_cli.dart';

/// Process environment for Supabase CLI subprocesses (profile auth token).
Map<String, String> supabaseProcessEnvironment(WorkspaceContext ctx) {
  final authEnv = loadProfileAuthEnvironment(ctx);
  return {
    ...Platform.environment,
    ...authEnv,
  };
}

SupabaseCli supabaseCliForContext(
  EnvManifest manifest,
  WorkspaceContext ctx, {
  SupabaseCli? fallback,
}) {
  final authEnv = loadProfileAuthEnvironment(ctx);
  if (authEnv.isEmpty) {
    return fallback ?? SupabaseCli(workdir: manifest.rootDir);
  }
  return SupabaseCli(
    workdir: manifest.rootDir,
    processEnvironment: supabaseProcessEnvironment(ctx),
  );
}

bool profileHasSupabaseToken(WorkspaceContext ctx) =>
    loadProfileAuthEnvironment(ctx).containsKey('SUPABASE_ACCESS_TOKEN');
