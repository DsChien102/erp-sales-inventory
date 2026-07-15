import '../doctor_service.dart';
import '../link_service.dart';
import '../manifest.dart';
import '../profile_registry.dart';
import '../sync_service.dart';

/// Result of a TUI orchestration action (no process exit).
class BridgeActionResult {
  BridgeActionResult({
    required this.ok,
    required this.lines,
    this.activeProfile,
    this.activeEnvironment,
  });

  final bool ok;
  final List<String> lines;
  final String? activeProfile;
  final String? activeEnvironment;
}

/// Wraps env services for the nocterm TUI without calling `exit`.
class TuiServicesBridge {
  TuiServicesBridge({required EnvManifest manifest})
      : manifest = manifest,
        syncService = SyncService(manifest: manifest),
        linkService = SupabaseLinkService(manifest: manifest),
        doctorService =
            DoctorService(manifest: manifest, skipNetwork: true);

  EnvManifest manifest;
  SyncService syncService;
  SupabaseLinkService linkService;
  DoctorService doctorService;

  ActiveState readState() => readActiveState(
        manifest.rootDir,
        defaultProfileId: manifest.profiles.defaultProfileId,
        defaultEnvironmentId: manifest.defaultEnvironmentId,
      );

  List<String> profileIds() =>
      manifest.profiles.profiles.keys.toList()..sort();

  /// Environments registered in the manifest that have a real secrets file
  /// for [profileId] (`<env>.env`), not `*.env.example` only.
  List<String> environmentIds({String? profileId}) {
    final state = readState();
    final profile = manifest.profiles.getProfile(profileId ?? state.profileId);
    final ids = <String>[];
    for (final envId in manifest.environments.keys) {
      if (profile.secretsFileFor(manifest.rootDir, envId).existsSync()) {
        ids.add(envId);
      }
    }
    ids.sort();
    return ids;
  }

  /// Reload manifest + state from disk.
  BridgeActionResult refresh() {
    manifest = EnvManifest.load(manifest.rootDir);
    syncService = SyncService(manifest: manifest);
    linkService = SupabaseLinkService(manifest: manifest);
    doctorService = DoctorService(manifest: manifest, skipNetwork: true);
    final state = readState();
    return BridgeActionResult(
      ok: true,
      lines: [
        'Refreshed manifest',
        'Active: profile=${state.profileId} environment=${state.environmentId}',
      ],
      activeProfile: state.profileId,
      activeEnvironment: state.environmentId,
    );
  }

  Future<BridgeActionResult> switchWorkspace({
    required String profileId,
    required String environmentId,
    String? targetId,
    bool skipLink = false,
  }) async {
    final lines = <String>[];
    try {
      manifest.profiles.getProfile(profileId);
      manifest.getEnvironment(environmentId);

      writeActiveState(
        manifest.rootDir,
        ActiveState(profileId: profileId, environmentId: environmentId),
      );
      final ctx = manifest.context(
        profileId: profileId,
        environmentId: environmentId,
      );

      if (!skipLink) {
        final link = await linkService.ensureLinked(ctx);
        lines.add(_linkSummary(link));
      }

      lines.add('Active: profile=${ctx.profileId} environment=${ctx.environmentId}');

      final sync = await syncService.sync(ctx, targetId: targetId);
      lines.addAll(_syncLines(sync));

      return BridgeActionResult(
        ok: sync.ok,
        lines: lines,
        activeProfile: ctx.profileId,
        activeEnvironment: ctx.environmentId,
      );
    } on Object catch (e) {
      lines.add('switch failed: $e');
      return BridgeActionResult(ok: false, lines: lines);
    }
  }

  Future<BridgeActionResult> sync({String? targetId}) async {
    final state = readState();
    final ctx = manifest.context(
      profileId: state.profileId,
      environmentId: state.environmentId,
    );
    final lines = <String>[];
    try {
      final link = await linkService.ensureLinked(ctx);
      lines.add(_linkSummary(link));
      final sync = await syncService.sync(ctx, targetId: targetId);
      lines.addAll(_syncLines(sync));
      return BridgeActionResult(
        ok: sync.ok,
        lines: lines,
        activeProfile: state.profileId,
        activeEnvironment: state.environmentId,
      );
    } on Object catch (e) {
      lines.add('sync failed: $e');
      return BridgeActionResult(ok: false, lines: lines);
    }
  }

  Future<BridgeActionResult> doctor({String? targetId}) async {
    final state = readState();
    final ctx = manifest.context(
      profileId: state.profileId,
      environmentId: state.environmentId,
    );
    try {
      final report = await doctorService.run(ctx, targetId: targetId);
      return BridgeActionResult(
        ok: report.ok,
        lines: _doctorLines(report),
        activeProfile: state.profileId,
        activeEnvironment: state.environmentId,
      );
    } on Object catch (e) {
      return BridgeActionResult(ok: false, lines: ['doctor failed: $e']);
    }
  }

  static String _linkSummary(LinkResult link) {
    switch (link.action) {
      case LinkAction.skipped:
        return 'Supabase link: skipped${link.detail == null ? '' : ' (${link.detail})'}';
      case LinkAction.alreadyLinked:
        return 'Supabase link: already linked to ${link.projectRef}';
      case LinkAction.linked:
        return 'Supabase link: switched to ${link.projectRef}';
    }
  }

  static List<String> _syncLines(SyncResult sync) {
    final lines = <String>[
      'Synced profile=${sync.profileId} environment=${sync.environmentId}',
    ];
    if (sync.writtenFiles.isEmpty && sync.failures.isEmpty) {
      lines.add('  (no writable targets)');
    }
    for (final entry in sync.writtenFiles.entries) {
      lines.add('  OK   ${entry.key}: ${entry.value.path}');
    }
    for (final entry in sync.failures.entries) {
      lines.add('  FAIL ${entry.key}: ${entry.value}');
    }
    return lines;
  }

  static List<String> _doctorLines(DoctorReport report) {
    final lines = <String>[
      'Profile: ${report.profileId}  Environment: ${report.environmentId}',
    ];
    for (final check in report.checks) {
      final icon = check.passed
          ? 'OK'
          : check.skipped
              ? 'SKIP'
              : 'FAIL';
      lines.add(
        '  [$icon] ${check.name}${check.detail == null ? '' : ' — ${check.detail}'}',
      );
    }
    return lines;
  }
}
