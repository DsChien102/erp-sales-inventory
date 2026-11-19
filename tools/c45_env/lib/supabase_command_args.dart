/// Parsed c45 flags vs passthrough args for `supabase` CLI delegation.
class SupabaseCommandArgs {
  SupabaseCommandArgs({
    required this.profileId,
    required this.environmentId,
    required this.supabaseArgs,
  });

  final String? profileId;
  final String environmentId;
  final List<String> supabaseArgs;

  static SupabaseCommandArgs parse(
    List<String> args, {
    required String defaultEnvironmentId,
  }) {
    return SupabaseCommandArgs(
      profileId: _parseProfileFlag(args),
      environmentId: _parseEnvFlagValue(args) ?? defaultEnvironmentId,
      supabaseArgs: _supabaseArgsOnly(args),
    );
  }

  static String? _parseProfileFlag(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--profile' && i + 1 < args.length) {
        return args[i + 1];
      }
    }
    return null;
  }

  static String? _parseEnvFlagValue(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--env' && i + 1 < args.length) {
        return args[i + 1];
      }
    }
    return null;
  }

  static List<String> _supabaseArgsOnly(List<String> args) {
    final result = <String>[];
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--profile' || args[i] == '--env') {
        if (i + 1 < args.length) {
          i++;
        }
        continue;
      }
      result.add(args[i]);
    }
    return result;
  }
}
