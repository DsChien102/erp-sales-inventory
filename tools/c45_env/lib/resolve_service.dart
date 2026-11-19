import 'manifest.dart';
import 'profile_registry.dart';

/// Resolved paths and fields for running app targets after env sync.
class ResolvedRunContext {
  ResolvedRunContext({
    required this.profileId,
    required this.environmentId,
    required this.secretsFile,
    required this.workspaceRoot,
    this.railwayEnvironment,
    this.targetId,
    this.envFile,
    this.envBasename,
    this.bindingFields = const {},
    this.secretsOnlyFiles = const {},
  });

  final String profileId;
  final String environmentId;
  final String secretsFile;
  final String workspaceRoot;
  final String? railwayEnvironment;
  final String? targetId;
  final String? envFile;
  final String? envBasename;
  final Map<String, String> bindingFields;
  final Map<String, String> secretsOnlyFiles;

  factory ResolvedRunContext.fromWorkspace(
    WorkspaceContext ctx,
    EnvManifest manifest, {
    String? targetId,
  }) {
    final env = ctx.environment;
    final binding = targetId == null ? null : env.binding(targetId);
    final envFilePath = binding?.envFile?.path;

    final secretsOnly = <String, String>{};
    for (final entry in manifest.targets.entries) {
      final target = entry.value;
      if (!target.writeEnvFile && target.secretsFile != null) {
        secretsOnly[entry.key] = target.secretsFile!.path;
      }
    }

    return ResolvedRunContext(
      profileId: ctx.profileId,
      environmentId: env.id,
      secretsFile: ctx.secretsFile.path,
      workspaceRoot: manifest.rootDir.path,
      railwayEnvironment: env.railwayEnvironment,
      targetId: targetId,
      envFile: envFilePath,
      envBasename: envFilePath == null
          ? null
          : Uri.file(envFilePath).pathSegments.last,
      bindingFields: binding?.fields ?? const {},
      secretsOnlyFiles: secretsOnly,
    );
  }
}
