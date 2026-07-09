import 'dart:convert';
import 'dart:io';

/// Supabase CLI integration: status, linked project, and link command.
class SupabaseCli {
  SupabaseCli({
    this.executable = 'supabase',
    this.workdir,
    this.processEnvironment,
  });

  final String executable;
  final Directory? workdir;
  final Map<String, String>? processEnvironment;

  Future<Map<String, String>> readStatusEnv() async {
    final result = await _run(['status', '-o', 'env']);
    if (result.exitCode != 0) {
      final stderr = '${result.stderr}'.trim();
      throw StateError(
        'supabase status failed (exit ${result.exitCode}). '
        'Is Supabase running? Try: supabase start\n$stderr',
      );
    }
    return parseEnvOutput('${result.stdout}');
  }

  Map<String, String> toCanonical(Map<String, String> statusEnv) {
    final apiUrl = statusEnv['API_URL'] ?? statusEnv['SUPABASE_URL'] ?? '';
    final anonKey = statusEnv['ANON_KEY'] ?? statusEnv['SUPABASE_ANON_KEY'] ?? '';
    final serviceRole = statusEnv['SERVICE_ROLE_KEY'] ??
        statusEnv['SUPABASE_SERVICE_ROLE_KEY'] ??
        '';
    return {
      if (apiUrl.isNotEmpty) 'SUPABASE_URL': apiUrl,
      if (anonKey.isNotEmpty) 'SUPABASE_ANON_KEY': anonKey,
      if (serviceRole.isNotEmpty) 'SUPABASE_SERVICE_ROLE_KEY': serviceRole,
    };
  }

  static String? readLinkedProjectRef(Directory? workdir) {
    if (workdir == null) {
      return null;
    }
    final refFile = File('${workdir.path}/supabase/.temp/project-ref');
    if (refFile.existsSync()) {
      final ref = refFile.readAsStringSync().trim();
      if (ref.isNotEmpty) {
        return ref;
      }
    }
    final linkedFile =
        File('${workdir.path}/supabase/.temp/linked-project.json');
    if (!linkedFile.existsSync()) {
      return null;
    }
    try {
      final json =
          jsonDecode(linkedFile.readAsStringSync()) as Map<String, dynamic>;
      final ref = json['ref'] as String? ?? '';
      return ref.isEmpty ? null : ref;
    } on Object {
      return null;
    }
  }

  Future<void> linkProject({
    required String projectRef,
    String? dbPassword,
  }) async {
    final args = [
      'link',
      '--project-ref',
      projectRef,
      '--yes',
    ];
    if (dbPassword != null && dbPassword.isNotEmpty) {
      args.addAll(['--password', dbPassword]);
    }
    final result = await _run(args);
    if (result.exitCode != 0) {
      final stderr = '${result.stderr}'.trim();
      final stdout = '${result.stdout}'.trim();
      throw StateError(
        'supabase link --project-ref $projectRef failed (exit ${result.exitCode}). '
        'Set SUPABASE_ACCESS_TOKEN in the profile auth.env file.\n'
        '${stderr.isEmpty ? stdout : stderr}',
      );
    }
  }

  static Map<String, String> parseEnvOutput(String stdout) {
    final values = <String, String>{};
    for (final line in stdout.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final eq = trimmed.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final key = trimmed.substring(0, eq).trim();
      var value = trimmed.substring(eq + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
    return values;
  }

  Future<ProcessResult> _run(List<String> args) async {
    return Process.run(
      executable,
      args,
      workingDirectory: workdir?.path,
      environment: processEnvironment,
    );
  }
}
