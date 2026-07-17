import 'dart:io';

import 'action_runner.dart';
import 'doctor_service.dart';
import 'link_service.dart';
import 'manifest.dart';
import 'process_runner.dart';
import 'profile_registry.dart';
import 'sync_service.dart';

/// Cross-platform orchestration for `vet45 run`.
class RunService {
  RunService({
    required this.manifest,
    required this.syncService,
    required this.linkService,
    required this.doctorService,
    ActionRunner? actionRunner,
    ProcessRunner? processRunner,
  }) : _actionRunner = actionRunner ??
            ActionRunner(
              manifest: manifest,
              doctorService: doctorService,
              processRunner: processRunner,
            );

  final EnvManifest manifest;
  final SyncService syncService;
  final SupabaseLinkService linkService;
  final DoctorService doctorService;
  final ActionRunner _actionRunner;

  Future<void> useProfile(String profileId) async {
    manifest.profiles.getProfile(profileId);
    final state = readActiveState(
      manifest.rootDir,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    writeActiveState(
      manifest.rootDir,
      ActiveState(profileId: profileId, environmentId: state.environmentId),
    );
    stdout.writeln('Active profile: $profileId');
  }

  /// Switch active profile and/or environment, align supabase link, sync app env.
  Future<void> switchWorkspace({
    String? profileId,
    String? environmentId,
    String? targetId,
    bool skipLink = false,
  }) async {
    final state = readActiveState(
      manifest.rootDir,
      defaultProfileId: manifest.profiles.defaultProfileId,
      defaultEnvironmentId: manifest.defaultEnvironmentId,
    );
    final nextProfile = profileId ?? state.profileId;
    final nextEnvironment = environmentId ?? state.environmentId;

    manifest.profiles.getProfile(nextProfile);
    manifest.getEnvironment(nextEnvironment);

    writeActiveState(
      manifest.rootDir,
      ActiveState(profileId: nextProfile, environmentId: nextEnvironment),
    );
    final ctx = manifest.context(
      profileId: nextProfile,
      environmentId: nextEnvironment,
    );

    if (!skipLink) {
      (await linkService.ensureLinked(ctx)).printSummary();
    }
    stdout.writeln(
      'Active: profile=${ctx.profileId} environment=${ctx.environmentId}',
    );
    await _syncOrExit(ctx, targetId: targetId);
  }

  Future<void> useAndSync(
    String environmentId, {
    String? profileId,
    String? targetId,
    bool skipLink = false,
  }) async {
    await switchWorkspace(
      profileId: profileId,
      environmentId: environmentId,
      targetId: targetId,
      skipLink: skipLink,
    );
  }

  Future<int> useSyncRun(
    String environmentId,
    String target,
    String action, {
    String? profileId,
    List<String> extraArgs = const [],
    bool skipLink = false,
  }) async {
    await useAndSync(
      environmentId,
      profileId: profileId,
      targetId: target,
      skipLink: skipLink,
    );
    return run(
      target,
      action,
      extraArgs: extraArgs,
      profileId: profileId,
      environmentId: environmentId,
      skipSync: true,
    );
  }

  Future<int> run(
    String target,
    String action, {
    List<String> extraArgs = const [],
    String? profileId,
    String? environmentId,
    bool skipSync = false,
  }) async {
    final ctx = manifest.context(
      profileId: profileId,
      environmentId: environmentId,
    );

    if (!manifest.targets.containsKey(target)) {
      stderr.writeln('Unknown run target: $target');
      stderr.writeln(
        'Available: ${manifest.targets.keys.join(', ')}',
      );
      return 64;
    }

    if (!skipSync) {
      await _syncOrExit(ctx, targetId: target);
    }

    return _actionRunner.run(
      ctx: ctx,
      targetId: target,
      actionId: action,
      extraArgs: extraArgs,
    );
  }

  Future<void> _syncOrExit(WorkspaceContext ctx, {String? targetId}) async {
    final result = await syncService.sync(ctx, targetId: targetId);
    if (!result.ok) {
      for (final entry in result.failures.entries) {
        stderr.writeln('sync failed for ${entry.key}: ${entry.value}');
      }
      exit(1);
    }
  }
}
