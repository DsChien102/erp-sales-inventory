import 'manifest.dart';

/// Parsed arguments for `c45 switch`.
class SwitchCommandArgs {
  SwitchCommandArgs({
    this.profileId,
    this.environmentId,
    this.targetId,
    this.skipLink = false,
    this.statusOnly = false,
  });

  final String? profileId;
  final String? environmentId;
  final String? targetId;
  final bool skipLink;
  final bool statusOnly;

  static SwitchCommandArgs parse(List<String> args, EnvManifest manifest) {
    if (args.isEmpty) {
      return SwitchCommandArgs(statusOnly: true);
    }

    final skipLink = args.contains('--skip-link');
    final filtered = args.where((a) => a != '--skip-link').toList();

    final profileFlag = _parseProfileFlag(filtered);
    final envFlag = _parseEnvFlagOnly(filtered);
    final targetId = _parseTargetFlag(filtered);
    final positionals = _positionals(filtered);

    String? profileId = profileFlag;
    String? environmentId = envFlag;

    if (positionals.isNotEmpty) {
      manifest.profiles.getProfile(positionals.first);
      profileId = positionals.first;
    }
    if (positionals.length >= 2) {
      manifest.getEnvironment(positionals[1]);
      environmentId = positionals[1];
    }

    final statusOnly = profileFlag == null &&
        envFlag == null &&
        targetId == null &&
        positionals.isEmpty;

    return SwitchCommandArgs(
      profileId: profileId,
      environmentId: environmentId,
      targetId: targetId,
      skipLink: skipLink,
      statusOnly: statusOnly,
    );
  }
}

String? _parseProfileFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--profile' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String? _parseEnvFlagOnly(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--env' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

String? _parseTargetFlag(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--target' && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

List<String> _positionals(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (_isFlagWithValue(args, i)) {
      i++;
      continue;
    }
    if (!args[i].startsWith('-')) {
      result.add(args[i]);
    }
  }
  return result;
}

bool _isFlagWithValue(List<String> args, int i) {
  return (args[i] == '--target' ||
          args[i] == '--env' ||
          args[i] == '--profile') &&
      i + 1 < args.length;
}
