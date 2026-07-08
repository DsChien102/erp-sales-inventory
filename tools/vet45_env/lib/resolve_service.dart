import 'manifest.dart';

/// Resolved paths and fields for running app targets after env sync.
class ResolvedRunContext {
  ResolvedRunContext({
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

  final String environmentId;
  final String secretsFile;
  final String deploySecretsFile;
  final String? railwayEnvironment;
  final String? erpFlavor;
  final String? erpEnvFile;
  final String? erpEnvBasename;
  final String? workerEnvFile;
  final String? workerDockerSupabaseUrl;

  factory ResolvedRunContext.fromManifest(
    EnvManifest manifest,
    String environmentId,
  ) {
    final env = manifest.getEnvironment(environmentId);
    final erp = env.erp;
    final worker = env.worker;
    return ResolvedRunContext(
      environmentId: environmentId,
      secretsFile: env.secretsFile.path,
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
