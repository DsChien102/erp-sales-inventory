/// Declarative run action from [vet45.target.json] `actions` block.
class ActionSpec {
  const ActionSpec({
    required this.command,
    this.args = const [],
    this.cwd = '.',
    this.env = const {},
    this.platforms = const [],
    this.requireEnvironments = const [],
    this.requireDoctorTargets = const [],
    this.preActions = const [],
    this.requireEnvFile = false,
    this.passEnvFile = false,
    this.requireRailwayEnvironment = false,
    this.localSupabaseCheck = false,
  });

  final String command;
  final List<String> args;
  final String cwd;
  final Map<String, String> env;
  final List<String> platforms;
  final List<String> requireEnvironments;
  final List<String> requireDoctorTargets;
  final List<String> preActions;
  final bool requireEnvFile;
  final bool passEnvFile;
  final bool requireRailwayEnvironment;
  final bool localSupabaseCheck;

  factory ActionSpec.fromJson(Map<String, dynamic> json) {
    final rawEnv = json['env'] as Map<String, dynamic>? ?? {};
    return ActionSpec(
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cwd: json['cwd'] as String? ?? '.',
      env: rawEnv.map((k, v) => MapEntry(k, v.toString())),
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requireEnvironments: (json['requireEnvironments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requireDoctorTargets: (json['requireDoctorTargets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preActions: (json['preActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requireEnvFile: json['requireEnvFile'] as bool? ?? false,
      passEnvFile: json['passEnvFile'] as bool? ?? false,
      requireRailwayEnvironment:
          json['requireRailwayEnvironment'] as bool? ?? false,
      localSupabaseCheck: json['localSupabaseCheck'] as bool? ?? false,
    );
  }
}

/// Expands `{{variable}}` placeholders using [vars].
class ActionTemplate {
  ActionTemplate(this.vars);

  final Map<String, String> vars;

  String expand(String input) {
    return input.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
      final key = match.group(1)!;
      return vars[key] ?? '';
    });
  }

  List<String> expandAll(Iterable<String> inputs) =>
      inputs.map(expand).toList();

  Map<String, String> expandEnv(Map<String, String> env) =>
      env.map((k, v) => MapEntry(k, expand(v)));
}

/// Template variables for action execution.
Map<String, String> buildActionTemplateVars({
  required String profileId,
  required String environmentId,
  required String workspaceRoot,
  required String secretsFile,
  String? railwayEnvironment,
  String? envFile,
  Map<String, String> bindingFields = const {},
}) {
  final vars = <String, String>{
    'profileId': profileId,
    'environmentId': environmentId,
    'workspaceRoot': workspaceRoot,
    'secretsFile': secretsFile,
    ...bindingFields,
  };
  if (railwayEnvironment != null && railwayEnvironment.isNotEmpty) {
    vars['railwayEnvironment'] = railwayEnvironment;
  }
  if (envFile != null) {
    vars['envFile'] = envFile;
    vars['envBasename'] = Uri.file(envFile).pathSegments.last;
  }
  return vars;
}
