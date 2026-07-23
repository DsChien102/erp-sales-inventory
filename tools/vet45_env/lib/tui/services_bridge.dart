import '../action_runner.dart';
import '../action_spec.dart';
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

class RunnableTargetInfo {
  RunnableTargetInfo({
    required this.id,
    required this.description,
  });

  final String id;
  final String description;
}

class ActionListItem {
  ActionListItem({
    required this.id,
    required this.description,
    required this.enabled,
    this.disabledReason,
  });

  final String id;
  final String description;
  final bool enabled;
  final String? disabledReason;
}

/// Flat hit for vim-style `/` action search (`targetId/actionId`).
class RunnableActionHit {
  RunnableActionHit({
    required this.targetId,
    required this.actionId,
    required this.description,
    required this.enabled,
    this.disabledReason,
  });

  final String targetId;
  final String actionId;
  final String description;
  final bool enabled;
  final String? disabledReason;

  String get label => '$targetId/$actionId';
}

/// Wraps env services for the nocterm TUI without calling `exit`.
class TuiServicesBridge {
  TuiServicesBridge({required EnvManifest manifest})
      : manifest = manifest,
        syncService = SyncService(manifest: manifest),
        linkService = SupabaseLinkService(manifest: manifest),
        doctorService =
            DoctorService(manifest: manifest, skipNetwork: true) {
    actionRunner = ActionRunner(
      manifest: manifest,
      doctorService: doctorService,
    );
  }

  EnvManifest manifest;
  SyncService syncService;
  SupabaseLinkService linkService;
  DoctorService doctorService;
  late ActionRunner actionRunner;

  ActiveState readState() => manifest.readState();

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

  WorkspaceContext activeContext() {
    final state = readState();
    return manifest.context(
      profileId: state.profileId,
      environmentId: state.environmentId,
    );
  }

  /// Targets that declare at least one action.
  List<RunnableTargetInfo> runnableTargets() {
    final list = <RunnableTargetInfo>[];
    for (final t in manifest.targets.values) {
      if (t.actions.isEmpty) {
        continue;
      }
      list.add(RunnableTargetInfo(id: t.id, description: t.description));
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  List<ActionListItem> actionsFor(String targetId) {
    final target = manifest.getTarget(targetId);
    final ctx = activeContext();
    final items = <ActionListItem>[];
    // Preserve declaration order from vet45.target.json.
    for (final id in target.actions.keys) {
      final spec = target.actions[id]!;
      final reason = actionRunner.disabledReason(
        spec: spec,
        ctx: ctx,
        targetId: targetId,
      );
      items.add(
        ActionListItem(
          id: id,
          description: spec.displayDescription,
          enabled: reason == null,
          disabledReason: reason,
        ),
      );
    }
    return items;
  }

  /// All target/action pairs (targets sorted by id; actions in JSON order).
  List<RunnableActionHit> allRunnableActions() {
    final ctx = activeContext();
    final hits = <RunnableActionHit>[];
    final targetIds = manifest.targets.keys.toList()..sort();
    for (final targetId in targetIds) {
      final target = manifest.targets[targetId]!;
      if (target.actions.isEmpty) {
        continue;
      }
      for (final actionId in target.actions.keys) {
        final spec = target.actions[actionId]!;
        final reason = actionRunner.disabledReason(
          spec: spec,
          ctx: ctx,
          targetId: targetId,
        );
        hits.add(
          RunnableActionHit(
            targetId: targetId,
            actionId: actionId,
            description: spec.displayDescription,
            enabled: reason == null,
            disabledReason: reason,
          ),
        );
      }
    }
    return hits;
  }

  /// Substring search over target id, action id, label, and description.
  /// Empty [query] returns [allRunnableActions].
  List<RunnableActionHit> searchActions(String query) {
    final all = allRunnableActions();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return all;
    }
    return all.where((hit) {
      final hay = [
        hit.targetId,
        hit.actionId,
        hit.label,
        hit.description,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  /// Sync preview of the resolved command line (templates expanded, no process).
  String previewActionCommand({
    required String targetId,
    required String actionId,
    List<String> extraArgs = const [],
  }) {
    final target = manifest.getTarget(targetId);
    final spec = target.actions[actionId];
    if (spec == null) {
      return '$targetId/$actionId';
    }
    final ctx = activeContext();
    final binding = ctx.environment.binding(targetId);
    final template = ActionTemplate(
      buildActionTemplateVars(
        profileId: ctx.profileId,
        environmentId: ctx.environment.id,
        workspaceRoot: manifest.rootDir.path,
        secretsFile: ctx.secretsFile.path,
        railwayEnvironment: ctx.environment.railwayEnvironment,
        envFile: binding?.envFile?.path,
        bindingFields: binding?.fields ?? const {},
      ),
    );
    final command = template.expand(spec.command);
    final args = [
      ...template.expandAll(spec.args),
      ...extraArgs,
    ];
    if (args.isEmpty) {
      return command;
    }
    return '$command ${args.join(' ')}';
  }

  Future<ActionLaunchPlan> resolveAction({
    required String targetId,
    required String actionId,
    List<String> extraArgs = const [],
  }) {
    return actionRunner.resolveLaunch(
      ctx: activeContext(),
      targetId: targetId,
      actionId: actionId,
      extraArgs: extraArgs,
    );
  }

  /// Reload manifest + state from disk.
  BridgeActionResult refresh() {
    manifest = EnvManifest.load(manifest.rootDir);
    syncService = SyncService(manifest: manifest);
    linkService = SupabaseLinkService(manifest: manifest);
    doctorService = DoctorService(manifest: manifest, skipNetwork: true);
    actionRunner = ActionRunner(
      manifest: manifest,
      doctorService: doctorService,
    );
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
