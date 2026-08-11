/// Parsed args for `vet45 admin create|grant|list`.
final class PlatformAdminCommandArgs {
  PlatformAdminCommandArgs({
    required this.subcommand,
    this.email,
    this.password,
    this.userId,
    this.profileId,
    this.environmentId,
    this.yes = false,
  });

  final String subcommand;
  final String? email;
  final String? password;
  final String? userId;
  final String? profileId;
  final String? environmentId;
  final bool yes;

  static PlatformAdminCommandArgs parse(List<String> args) {
    if (args.isEmpty) {
      throw StateError(
        'Usage: vet45 admin create|grant|list [--email ...] [--password ...] '
        '[--user-id ...] [--env ...] [--profile ...] [--yes]',
      );
    }

    final subcommand = args.first;
    if (subcommand != 'create' &&
        subcommand != 'grant' &&
        subcommand != 'list') {
      throw StateError(
        'Unknown admin subcommand: $subcommand (use create|grant|list)',
      );
    }

    final rest = args.skip(1).toList();
    final yes = rest.contains('--yes');
    final filtered = rest.where((a) => a != '--yes').toList();

    return PlatformAdminCommandArgs(
      subcommand: subcommand,
      email: _flagValue(filtered, '--email'),
      password: _flagValue(filtered, '--password'),
      userId: _flagValue(filtered, '--user-id'),
      profileId: _flagValue(filtered, '--profile'),
      environmentId: _flagValue(filtered, '--env'),
      yes: yes,
    );
  }

  static String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      if (args[i] == flag && i + 1 < args.length) {
        return args[i + 1];
      }
    }
    return null;
  }
}
