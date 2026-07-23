import 'package:nocterm/nocterm.dart';

import 'panels/environments_panel.dart';
import 'panels/log_panel.dart';
import 'panels/profiles_panel.dart';
import 'panels/status_panel.dart';
import 'services_bridge.dart';
import 'widgets/footer_help.dart';

enum FocusPanel { profiles, environments, status, log }

class Vet45TuiShell extends StatefulComponent {
  const Vet45TuiShell({super.key, required this.bridge});

  final TuiServicesBridge bridge;

  @override
  State<Vet45TuiShell> createState() => Vet45TuiShellState();
}

class Vet45TuiShellState extends State<Vet45TuiShell> {
  static const _logCap = 200;

  late FocusPanel focus;
  late List<String> profiles;
  late List<String> environments;
  late String activeProfile;
  late String activeEnvironment;
  late int profileCursor;
  late int envCursor;
  List<String> doctorLines = const [];
  final List<String> logs = [];
  bool busy = false;
  String? confirmPending;

  final profileScroll = ScrollController();
  final envScroll = ScrollController();
  final statusScroll = ScrollController();
  final logScroll = AutoScrollController();

  TuiServicesBridge get bridge => component.bridge;

  @override
  void initState() {
    super.initState();
    focus = FocusPanel.profiles;
    _loadFromBridge(appendLog: false);
    _appendLog('Ready. Select profile/env then Enter to switch.');
  }

  @override
  void dispose() {
    profileScroll.dispose();
    envScroll.dispose();
    statusScroll.dispose();
    logScroll.dispose();
    super.dispose();
  }

  void _ensureProfileVisible() {
    if (profiles.isEmpty) {
      return;
    }
    _afterLayout(() => profileScroll.ensureIndexVisible(index: profileCursor));
  }

  void _ensureEnvVisible() {
    if (environments.isEmpty) {
      return;
    }
    _afterLayout(() => envScroll.ensureIndexVisible(index: envCursor));
  }

  void _afterLayout(void Function() fn) {
    try {
      TerminalBinding.instance.addPostFrameCallback((_) => fn());
    } on Object {
      fn();
    }
  }

  bool _scrollFocusedPanel({required bool down, double lines = 1}) {
    final controller = switch (focus) {
      FocusPanel.profiles => profileScroll,
      FocusPanel.environments => envScroll,
      FocusPanel.status => statusScroll,
      FocusPanel.log => logScroll,
    };
    if (down) {
      controller.scrollDown(lines);
    } else {
      controller.scrollUp(lines);
    }
    return true;
  }

  void _loadFromBridge({bool appendLog = true}) {
    final state = bridge.readState();
    profiles = bridge.profileIds();
    activeProfile = state.profileId;
    activeEnvironment = state.environmentId;
    profileCursor = profiles.indexOf(activeProfile).clamp(
          0,
          profiles.isEmpty ? 0 : profiles.length - 1,
        );
    _reloadEnvironmentsForSelectedProfile();
    if (appendLog) {
      _appendLog(
        'Active: profile=$activeProfile environment=$activeEnvironment',
      );
    }
  }

  /// Environments for the profile under the cursor (secrets `<env>.env` only).
  void _reloadEnvironmentsForSelectedProfile() {
    final profileId =
        profiles.isEmpty ? activeProfile : profiles[profileCursor];
    environments = bridge.environmentIds(profileId: profileId);
    final preferred = environments.contains(activeEnvironment) &&
            profileId == activeProfile
        ? activeEnvironment
        : (environments.isEmpty ? null : environments.first);
    if (preferred == null) {
      envCursor = 0;
    } else {
      envCursor = environments.indexOf(preferred).clamp(0, environments.length - 1);
    }
  }

  void _appendLog(String line) {
    logs.add(line);
    while (logs.length > _logCap) {
      logs.removeAt(0);
    }
  }

  void _appendLogs(List<String> lines) {
    for (final line in lines) {
      _appendLog(line);
    }
  }

  String get selectedProfile =>
      profiles.isEmpty ? activeProfile : profiles[profileCursor];

  String get selectedEnvironment =>
      environments.isEmpty ? activeEnvironment : environments[envCursor];

  void _cycleFocus({required bool forward}) {
    const order = FocusPanel.values;
    final i = order.indexOf(focus);
    focus = order[(i + (forward ? 1 : -1)) % order.length];
  }

  Future<void> _runBusy(Future<BridgeActionResult> Function() action) async {
    if (busy) {
      return;
    }
    setState(() => busy = true);
    try {
      final result = await action();
      setState(() {
        _appendLogs(result.lines);
        if (result.activeProfile != null) {
          activeProfile = result.activeProfile!;
        }
        if (result.activeEnvironment != null) {
          activeEnvironment = result.activeEnvironment!;
        }
        if (result.lines.any((l) => l.startsWith('  [') || l.startsWith('Profile:'))) {
          doctorLines = result.lines
              .where((l) => l.startsWith('  [') || l.startsWith('Profile:'))
              .toList();
        }
        busy = false;
        confirmPending = null;
      });
    } on Object catch (e) {
      setState(() {
        _appendLog('error: $e');
        busy = false;
        confirmPending = null;
      });
    }
  }

  Future<void> _requestSwitch() async {
    if (busy || profiles.isEmpty || environments.isEmpty) {
      return;
    }
    final profile = selectedProfile;
    final env = selectedEnvironment;
    final bothChanged =
        profile != activeProfile && env != activeEnvironment;
    if (bothChanged && confirmPending == null) {
      setState(() => confirmPending = '$profile/$env');
      return;
    }
    await _runBusy(
      () => bridge.switchWorkspace(profileId: profile, environmentId: env),
    );
  }

  bool _onKey(KeyboardEvent event) {
    final key = event.logicalKey;

    if (confirmPending != null) {
      final ch = event.character?.toLowerCase();
      if (ch == 'y' || key == LogicalKey.enter) {
        final pending = confirmPending!;
        final parts = pending.split('/');
        _runBusy(
          () => bridge.switchWorkspace(
            profileId: parts[0],
            environmentId: parts[1],
          ),
        );
        return true;
      }
      if (ch == 'n' || key == LogicalKey.escape) {
        setState(() => confirmPending = null);
        return true;
      }
      return true;
    }

    if (key == LogicalKey.keyQ ||
        (key == LogicalKey.keyC && event.isControlPressed)) {
      shutdownApp(0);
      return true;
    }

    if (busy) {
      return true;
    }

    if (key == LogicalKey.tab) {
      setState(() => _cycleFocus(forward: !event.isShiftPressed));
      return true;
    }
    if (event.character == 'h' || key == LogicalKey.arrowLeft) {
      if (focus == FocusPanel.environments) {
        setState(() => focus = FocusPanel.profiles);
        return true;
      }
    }
    if (event.character == 'l' || key == LogicalKey.arrowRight) {
      if (focus == FocusPanel.profiles) {
        setState(() => focus = FocusPanel.environments);
        return true;
      }
    }

    if (key == LogicalKey.arrowDown || event.character == 'j') {
      setState(() {
        if (focus == FocusPanel.profiles && profiles.isNotEmpty) {
          profileCursor = (profileCursor + 1).clamp(0, profiles.length - 1);
          _reloadEnvironmentsForSelectedProfile();
          _ensureProfileVisible();
          _ensureEnvVisible();
        } else if (focus == FocusPanel.environments && environments.isNotEmpty) {
          envCursor = (envCursor + 1).clamp(0, environments.length - 1);
          _ensureEnvVisible();
        } else if (focus == FocusPanel.status || focus == FocusPanel.log) {
          _scrollFocusedPanel(down: true);
        }
      });
      return true;
    }
    if (key == LogicalKey.arrowUp || event.character == 'k') {
      setState(() {
        if (focus == FocusPanel.profiles && profiles.isNotEmpty) {
          profileCursor = (profileCursor - 1).clamp(0, profiles.length - 1);
          _reloadEnvironmentsForSelectedProfile();
          _ensureProfileVisible();
          _ensureEnvVisible();
        } else if (focus == FocusPanel.environments && environments.isNotEmpty) {
          envCursor = (envCursor - 1).clamp(0, environments.length - 1);
          _ensureEnvVisible();
        } else if (focus == FocusPanel.status || focus == FocusPanel.log) {
          _scrollFocusedPanel(down: false);
        }
      });
      return true;
    }
    if (key == LogicalKey.pageDown) {
      if (focus == FocusPanel.status || focus == FocusPanel.log) {
        setState(() => _scrollFocusedPanel(down: true, lines: 10));
        return true;
      }
    }
    if (key == LogicalKey.pageUp) {
      if (focus == FocusPanel.status || focus == FocusPanel.log) {
        setState(() => _scrollFocusedPanel(down: false, lines: 10));
        return true;
      }
    }

    if (key == LogicalKey.enter) {
      _requestSwitch();
      return true;
    }

    final ch = event.character?.toLowerCase();
    if (ch == 's') {
      _runBusy(() => bridge.sync());
      return true;
    }
    if (ch == 'd') {
      _runBusy(() => bridge.doctor());
      return true;
    }
    if (ch == 'r') {
      setState(() {
        final result = bridge.refresh();
        profiles = bridge.profileIds();
        if (result.activeProfile != null) {
          activeProfile = result.activeProfile!;
        }
        if (result.activeEnvironment != null) {
          activeEnvironment = result.activeEnvironment!;
        }
        profileCursor =
            profiles.indexOf(activeProfile).clamp(0, profiles.length - 1);
        _reloadEnvironmentsForSelectedProfile();
        _appendLogs(result.lines);
      });
      return true;
    }
    if (ch == '?') {
      setState(() {
        _appendLog(
          'Keys: q quit | Tab focus | ↑↓/jk select/scroll | PgUp/PgDn | ←→/hl panels | Enter switch | s sync | d doctor | r refresh',
        );
      });
      return true;
    }

    return false;
  }

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return Focusable(
      focused: true,
      onKeyEvent: _onKey,
      child: Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'vet45 TUI',
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ProfilesPanel(
                      profiles: profiles,
                      activeProfile: activeProfile,
                      cursor: profileCursor,
                      focused: focus == FocusPanel.profiles,
                      scrollController: profileScroll,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 3,
                    child: EnvironmentsPanel(
                      environments: environments,
                      activeEnvironment: activeEnvironment,
                      cursor: envCursor,
                      focused: focus == FocusPanel.environments,
                      scrollController: envScroll,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: StatusPanel(
                activeProfile: activeProfile,
                activeEnvironment: activeEnvironment,
                doctorLines: doctorLines,
                focused: focus == FocusPanel.status,
                busy: busy,
                scrollController: statusScroll,
              ),
            ),
            Expanded(
              flex: 3,
              child: LogPanel(
                logs: logs,
                focused: focus == FocusPanel.log,
                scrollController: logScroll,
              ),
            ),
            FooterHelp(busy: busy, confirmPending: confirmPending),
          ],
        ),
      ),
    );
  }
}
