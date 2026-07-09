import 'manifest.dart';
import 'profile_registry.dart';

/// Resolved paths and fields for running app targets after env sync.
class ResolvedRunContext {
  ResolvedRunContext({
    required this.profileId,
    required this.environmentId,
    required this.secretsFile,
    required this.deploySecretsFile,
    this.railwayEnvironment,
    this.erpFlavor,
    this.erpEnvFile,
    this.erpEnvBasename,
    this.workerEnvFile,
    this.workerDockerSupabaseUrl,
  });

  final String profileId;
  final String environmentId;
  final String secretsFile;
  final String deploySecretsFile;
  final String? railwayEnvironment;
  final String? erpFlavor;
  final String? erpEnvFile;
  final String? erpEnvBasename;
  final String? workerEnvFile;
  final String? workerDockerSupabaseUrl;

  factory ResolvedRunContext.fromWorkspace(WorkspaceContext ctx, EnvManifest manifest) {
    final env = ctx.environment;
    final erp = env.erp;
    final worker = env.worker;
    return ResolvedRunContext(
      profileId: ctx.profileId,
      environmentId: env.id,
      secretsFile: ctx.secretsFile.path,
      deploySecretsFile: manifest.deploySecretsFile.path,
      railwayEnvironment: env.railwayEnvironment,
      erpFlavor: erp?.flavor,
      erpEnvFile: erp?.envFile?.path,
      erpEnvBasename: erp?.envFile?.uri.pathSegments.last,
      workerEnvFile: worker?.envFile?.path,
      workerDockerSupabaseUrl: worker?.dockerSupabaseUrl,
    );
  }
}
