import 'manifest.dart';
import 'profile_registry.dart';
import 'secrets_loader.dart';
import 'supabase_admin_client.dart';
import 'supabase_cli.dart';
import 'supabase_context.dart';

/// Result of create / grant platform admin.
final class PlatformAdminResult {
  const PlatformAdminResult({
    required this.userId,
    required this.email,
    required this.createdUser,
    required this.granted,
    this.generatedPassword,
    this.existingUserMessage,
  });

  final String userId;
  final String email;
  final bool createdUser;
  final bool granted;
  final String? generatedPassword;
  final String? existingUserMessage;
}

/// Bootstrap platform admins via Auth Admin API + `iam.platform_admins`.
final class PlatformAdminService {
  PlatformAdminService({
    required this.manifest,
    SupabaseCli? supabaseCli,
    SupabaseAdminHttp? http,
    Future<Map<String, String>> Function(WorkspaceContext ctx)? loadCanonical,
  })  : _supabaseCli = supabaseCli ?? SupabaseCli(workdir: manifest.rootDir),
        _http = http,
        _loadCanonical = loadCanonical;

  final EnvManifest manifest;
  final SupabaseCli _supabaseCli;
  final SupabaseAdminHttp? _http;
  final Future<Map<String, String>> Function(WorkspaceContext ctx)?
      _loadCanonical;

  Future<PlatformAdminResult> create({
    required WorkspaceContext ctx,
    required String email,
    String? password,
    bool yes = false,
  }) async {
    _requireYesIfNeeded(ctx, yes);
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw StateError('Valid --email is required');
    }

    return _withClient(ctx, (client) async {
      var generatedPassword = password;
      var passwordWasGenerated = false;
      if (generatedPassword == null || generatedPassword.isEmpty) {
        generatedPassword = generateTickSecret();
        passwordWasGenerated = true;
      }

      final createResult = await client.createUser(
        email: normalizedEmail,
        password: generatedPassword,
      );

      late final String userId;
      var createdUser = createResult.created;
      String? existingMessage;

      if (createResult.userId != null) {
        userId = createResult.userId!;
      } else {
        final existingId = await client.findUserIdByEmail(normalizedEmail);
        if (existingId == null || existingId.isEmpty) {
          throw StateError(
            'User with email $normalizedEmail already exists but could not be resolved',
          );
        }
        userId = existingId;
        createdUser = false;
        existingMessage =
            'User already exists; skipped create (password unchanged). Granting platform admin.';
      }

      await client.grantPlatformAdmin(userId);

      return PlatformAdminResult(
        userId: userId,
        email: normalizedEmail,
        createdUser: createdUser,
        granted: true,
        generatedPassword: passwordWasGenerated && createdUser
            ? generatedPassword
            : null,
        existingUserMessage: existingMessage,
      );
    });
  }

  Future<PlatformAdminResult> grant({
    required WorkspaceContext ctx,
    String? email,
    String? userId,
    bool yes = false,
  }) async {
    _requireYesIfNeeded(ctx, yes);
    return _withClient(ctx, (client) async {
      late final String resolvedUserId;
      late final String resolvedEmail;

      if (userId != null && userId.trim().isNotEmpty) {
        resolvedUserId = userId.trim();
        resolvedEmail = email?.trim().toLowerCase() ?? resolvedUserId;
      } else if (email != null && email.trim().isNotEmpty) {
        resolvedEmail = email.trim().toLowerCase();
        final found = await client.findUserIdByEmail(resolvedEmail);
        if (found == null || found.isEmpty) {
          throw StateError('No auth user found for email $resolvedEmail');
        }
        resolvedUserId = found;
      } else {
        throw StateError('Provide --email or --user-id');
      }

      await client.grantPlatformAdmin(resolvedUserId);
      return PlatformAdminResult(
        userId: resolvedUserId,
        email: resolvedEmail,
        createdUser: false,
        granted: true,
      );
    });
  }

  Future<List<Map<String, dynamic>>> list({
    required WorkspaceContext ctx,
  }) {
    return _withClient(ctx, (client) => client.listPlatformAdmins());
  }

  Future<T> _withClient<T>(
    WorkspaceContext ctx,
    Future<T> Function(SupabaseAdminClient client) run,
  ) async {
    final client = await _clientFor(ctx);
    try {
      return await run(client);
    } finally {
      client.close();
    }
  }

  void _requireYesIfNeeded(WorkspaceContext ctx, bool yes) {
    final envId = ctx.environmentId;
    if (envId == 'local' || envId == 'development') {
      return;
    }
    if (!yes) {
      throw StateError(
        'Refusing to modify platform admins on "$envId" without --yes',
      );
    }
  }

  Future<SupabaseAdminClient> _clientFor(WorkspaceContext ctx) async {
    final loadCanonical = _loadCanonical;
    final canonical = loadCanonical != null
        ? await loadCanonical(ctx)
        : await _defaultLoadCanonical(ctx);

    final url = (canonical['SUPABASE_CONNECTION_URL'] ??
            canonical['SUPABASE_URL'] ??
            '')
        .trim();
    final serviceRole = (canonical['SUPABASE_SERVICE_ROLE_KEY'] ??
            canonical['SERVICE_ROLE_KEY'] ??
            '')
        .trim();

    if (url.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_CONNECTION_URL in secrets '
        '(profile=${ctx.profileId} env=${ctx.environmentId})',
      );
    }
    if (serviceRole.isEmpty) {
      throw StateError(
        'Missing SUPABASE_SERVICE_ROLE_KEY in secrets '
        '(profile=${ctx.profileId} env=${ctx.environmentId}). '
        'For local: run supabase start then vet45 sync',
      );
    }

    return SupabaseAdminClient(
      baseUrl: url,
      serviceRoleKey: serviceRole,
      http: _http,
    );
  }

  Future<Map<String, String>> _defaultLoadCanonical(WorkspaceContext ctx) async {
    final env = ctx.environment;
    final fromSecrets = loadDotEnv(ctx.secretsFile);
    final cli = supabaseCliForContext(manifest, ctx, fallback: _supabaseCli);
    if (env.supabaseSource == 'supabase_cli') {
      final status = await cli.readStatusEnv();
      final fromCli = cli.toCanonical(status);
      return {...fromCli, ...fromSecrets};
    }
    if (env.cliFallback) {
      try {
        final status = await cli.readStatusEnv();
        final fromCli = cli.toCanonical(status);
        return {...fromCli, ...fromSecrets};
      } on Object {
        return Map<String, String>.from(fromSecrets);
      }
    }
    return Map<String, String>.from(fromSecrets);
  }
}
