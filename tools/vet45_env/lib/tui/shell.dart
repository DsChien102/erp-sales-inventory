import 'package:nocterm/nocterm.dart';

import '../action_runner.dart';
import 'panels/actions_panel.dart';
import 'panels/environments_panel.dart';
import 'panels/log_panel.dart';
import 'panels/profiles_panel.dart';
import 'panels/session_tabs.dart';
import 'panels/session_terminal.dart';
import 'panels/status_panel.dart';
import 'panels/targets_panel.dart';
import 'parse_cli_args.dart';
import 'services_bridge.dart';
import 'session_manager.dart';
import 'widgets/extra_args_popup.dart';
import 'widgets/footer_help.dart';
import 'widgets/mode_bar.dart';

enum FocusPanelEnv { profiles, environments, status, log }

enum FocusPanelRun { targets, actions, sessions, terminal }

class Vet45TuiShell extends StatefulComponent {
  const Vet45TuiShell({super.key, required this.bridge});

  final TuiServicesBridge bridge;

  @override
  State<Vet45TuiShell> createState() => Vet45TuiShellState();
}

class Vet45TuiShellState extends State<Vet45TuiShell> {
  static const _logCap = 200;

  TuiMode mode = TuiMode.env;
  FocusPanelEnv envFocus = FocusPanelEnv.profiles;
  FocusPanelRun runFocus = FocusPanelRun.sessions;

  /// When true, Targets/Actions picker is shown (opened with `n`).
  bool newSessionPicker = false;

  /// Prompt for additional CLI args before launching (`a` in picker).
  bool extraArgsPrompt = false;
  String extraArgsDraft = '';

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
  String? quitConfirmPending;

  List<RunnableTargetInfo> targets = const [];
  List<ActionListItem> actions = const [];
  int targetCursor = 0;
  int actionCursor = 0;

  late final SessionManager sessions;

  final profileScroll = ScrollController();
  final envScroll = ScrollController();
  final statusScroll = ScrollController();
  final logScroll = AutoScrollController();
  final targetScroll = ScrollController();
  final actionScroll = ScrollController();
  final sessionScroll = ScrollController();

  TuiServicesBridge get bridge => component.bridge;

  @override
  void initState() {
    super.initState();
    sessions = SessionManager(onSessionExit: _onSessionExit);
    _loadFromBridge(appendLog: false);
    _reloadRunLists();
    _appendLog('Ready. [1] Env  [2] Run | n new session | Enter switch.');
  }

  void _onSessionExit(TuiSession session) {
    if (!mounted) {
      return;
    }
    setState(() {
      final active = sessions.activeSession;
      if (runFocus == FocusPanelRun.terminal &&
          active != null &&
          identical(active, session)) {
        runFocus = FocusPanelRun.sessions;
      }
      _appendLog(
        'Session ${session.label} exited'
        '${session.exitCode != null ? ' (${session.exitCode})' : ''}',
      );
    });
  }

  @override
  void dispose() {
    for (final s in List<TuiSession>.from(sessions.sessions)) {
      if (s.controller.isRunning) {
        s.controller.kill();
      }
    }
    sessions.sessions.clear();
    profileScroll.dispose();
    envScroll.dispose();
    statusScroll.dispose();
    logScroll.dispose();
    targetScroll.dispose();
    actionScroll.dispose();
    sessionScroll.dispose();
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

  void _ensureTargetVisible() {
    if (targets.isEmpty) {
      return;
    }
    _afterLayout(() => targetScroll.ensureIndexVisible(index: targetCursor));
  }

  void _ensureActionVisible() {
    if (actions.isEmpty) {
      return;
    }
    _afterLayout(() => actionScroll.ensureIndexVisible(index: actionCursor));
  }

  void _ensureSessionVisible() {
    if (!sessions.hasSessions) {
      return;
    }
    _afterLayout(
      () => sessionScroll.ensureIndexVisible(index: sessions.activeIndex),
    );
  }

  void _afterLayout(void Function() fn) {
    try {
      TerminalBinding.instance.addPostFrameCallback((_) => fn());
    } on Object {
      fn();
    }
  }

  bool _scrollFocusedEnvPanel({required bool down, double lines = 1}) {
    final controller = switch (envFocus) {
      FocusPanelEnv.profiles => profileScroll,
      FocusPanelEnv.environments => envScroll,
      FocusPanelEnv.status => statusScroll,
      FocusPanelEnv.log => logScroll,
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
      envCursor =
          environments.indexOf(preferred).clamp(0, environments.length - 1);
    }
  }

  void _reloadRunLists() {
    targets = bridge.runnableTargets();
    if (targets.isEmpty) {
      targetCursor = 0;
      actions = const [];
      actionCursor = 0;
      return;
    }
    targetCursor = targetCursor.clamp(0, targets.length - 1);
    _reloadActionsForSelectedTarget();
  }

  void _reloadActionsForSelectedTarget() {
    if (targets.isEmpty) {
      actions = const [];
      actionCursor = 0;
      return;
    }
    final id = targets[targetCursor].id;
    actions = bridge.actionsFor(id);
    actionCursor =
        actions.isEmpty ? 0 : actionCursor.clamp(0, actions.length - 1);
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

  void _cycleEnvFocus({required bool forward}) {
    const order = FocusPanelEnv.values;
    final i = order.indexOf(envFocus);
    envFocus = order[(i + (forward ? 1 : -1) + order.length) % order.length];
  }

  bool get _terminalCapturesKeys =>
      mode == TuiMode.run &&
      !newSessionPicker &&
      runFocus == FocusPanelRun.terminal &&
      sessions.activeSession?.isRunning == true;

  void _openNewSessionPicker() {
    _reloadRunLists();
    newSessionPicker = true;
    extraArgsPrompt = false;
    extraArgsDraft = '';
    runFocus = FocusPanelRun.targets;
    _appendLog(
      'New session: pick target/action, Enter to start, a + args, Esc cancel',
    );
  }

  void _closeNewSessionPicker({FocusPanelRun? focus}) {
    newSessionPicker = false;
    extraArgsPrompt = false;
    extraArgsDraft = '';
    runFocus = focus ??
        (sessions.hasSessions
            ? FocusPanelRun.terminal
            : FocusPanelRun.sessions);
  }

  void _openExtraArgsPrompt() {
    if (busy || targets.isEmpty || actions.isEmpty) {
      return;
    }
    extraArgsPrompt = true;
    extraArgsDraft = '';
  }

  void _cancelExtraArgsPrompt() {
    extraArgsPrompt = false;
    extraArgsDraft = '';
  }

  void _cycleRunFocus({required bool forward}) {
    final order = newSessionPicker
        ? const [FocusPanelRun.targets, FocusPanelRun.actions]
        : [
            FocusPanelRun.sessions,
            if (sessions.hasSessions) FocusPanelRun.terminal,
          ];
    if (order.isEmpty) {
      return;
    }
    var i = order.indexOf(runFocus);
    if (i < 0) {
      runFocus = order.first;
      return;
    }
    i = (i + (forward ? 1 : -1) + order.length) % order.length;
    runFocus = order[i];
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
        if (result.lines
            .any((l) => l.startsWith('  [') || l.startsWith('Profile:'))) {
          doctorLines = result.lines
              .where((l) => l.startsWith('  [') || l.startsWith('Profile:'))
              .toList();
        }
        _reloadRunLists();
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

  Future<void> _launchSelectedAction({List<String> extraArgs = const []}) async {
    if (busy || targets.isEmpty || actions.isEmpty) {
      return;
    }
    final action = actions[actionCursor];
    if (!action.enabled) {
      setState(() {
        _appendLog(
          'Cannot run ${targets[targetCursor].id}/${action.id}: '
          '${action.disabledReason ?? 'disabled'}',
        );
      });
      return;
    }
    setState(() {
      busy = true;
      extraArgsPrompt = false;
    });
    try {
      final plan = await bridge.resolveAction(
        targetId: targets[targetCursor].id,
        actionId: action.id,
        extraArgs: extraArgs,
      );
      setState(() {
        try {
          sessions.open(plan);
          _closeNewSessionPicker(focus: FocusPanelRun.terminal);
          final extras = extraArgs.isEmpty ? '' : ' ${extraArgs.join(' ')}';
          _appendLog('Started session ${plan.label}$extras');
        } on StateError catch (e) {
          _appendLog(e.message);
        }
        busy = false;
        extraArgsDraft = '';
      });
    } on ActionLaunchException catch (e) {
      setState(() {
        _appendLog(e.message);
        busy = false;
        extraArgsDraft = '';
      });
    } on Object catch (e) {
      setState(() {
        _appendLog('launch failed: $e');
        busy = false;
        extraArgsDraft = '';
      });
    }
  }

  void _requestQuit() {
    if (sessions.hasSessions && quitConfirmPending == null) {
      setState(() => quitConfirmPending = 'quit');
      return;
    }
    _doQuit();
  }

  Future<void> _doQuit() async {
    await sessions.closeAll();
    shutdownApp(0);
  }

  bool _onKey(KeyboardEvent event) {
    final key = event.logicalKey;

    if (_terminalCapturesKeys) {
      if (key == LogicalKey.keyO && event.isControlPressed) {
        setState(() => runFocus = FocusPanelRun.sessions);
        return true;
      }
      return false;
    }

    if (extraArgsPrompt) {
      return _onExtraArgsPromptKey(event);
    }

    if (quitConfirmPending != null) {
      final ch = event.character?.toLowerCase();
      if (ch == 'y' || key == LogicalKey.enter) {
        _doQuit();
        return true;
      }
      if (ch == 'n' || key == LogicalKey.escape) {
        setState(() => quitConfirmPending = null);
        return true;
      }
      return true;
    }

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
      _requestQuit();
      return true;
    }

    if (event.character == '1') {
      setState(() {
        mode = TuiMode.env;
        newSessionPicker = false;
        extraArgsPrompt = false;
        extraArgsDraft = '';
        quitConfirmPending = null;
      });
      return true;
    }
    if (event.character == '2') {
      setState(() {
        mode = TuiMode.run;
        newSessionPicker = false;
        extraArgsPrompt = false;
        extraArgsDraft = '';
        runFocus = FocusPanelRun.sessions;
        _reloadRunLists();
        quitConfirmPending = null;
      });
      return true;
    }

    if (busy) {
      return true;
    }

    if (key == LogicalKey.tab) {
      setState(() {
        if (mode == TuiMode.env) {
          _cycleEnvFocus(forward: !event.isShiftPressed);
        } else {
          _cycleRunFocus(forward: !event.isShiftPressed);
        }
      });
      return true;
    }

    if (mode == TuiMode.env) {
      return _onEnvKey(event);
    }
    return _onRunKey(event);
  }

  bool _onEnvKey(KeyboardEvent event) {
    final key = event.logicalKey;

    if (event.character == 'h' || key == LogicalKey.arrowLeft) {
      if (envFocus == FocusPanelEnv.environments) {
        setState(() => envFocus = FocusPanelEnv.profiles);
        return true;
      }
    }
    if (event.character == 'l' || key == LogicalKey.arrowRight) {
      if (envFocus == FocusPanelEnv.profiles) {
        setState(() => envFocus = FocusPanelEnv.environments);
        return true;
      }
    }

    if (key == LogicalKey.arrowDown || event.character == 'j') {
      setState(() {
        if (envFocus == FocusPanelEnv.profiles && profiles.isNotEmpty) {
          profileCursor = (profileCursor + 1).clamp(0, profiles.length - 1);
          _reloadEnvironmentsForSelectedProfile();
          _ensureProfileVisible();
          _ensureEnvVisible();
        } else if (envFocus == FocusPanelEnv.environments &&
            environments.isNotEmpty) {
          envCursor = (envCursor + 1).clamp(0, environments.length - 1);
          _ensureEnvVisible();
        } else if (envFocus == FocusPanelEnv.status ||
            envFocus == FocusPanelEnv.log) {
          _scrollFocusedEnvPanel(down: true);
        }
      });
      return true;
    }
    if (key == LogicalKey.arrowUp || event.character == 'k') {
      setState(() {
        if (envFocus == FocusPanelEnv.profiles && profiles.isNotEmpty) {
          profileCursor = (profileCursor - 1).clamp(0, profiles.length - 1);
          _reloadEnvironmentsForSelectedProfile();
          _ensureProfileVisible();
          _ensureEnvVisible();
        } else if (envFocus == FocusPanelEnv.environments &&
            environments.isNotEmpty) {
          envCursor = (envCursor - 1).clamp(0, environments.length - 1);
          _ensureEnvVisible();
        } else if (envFocus == FocusPanelEnv.status ||
            envFocus == FocusPanelEnv.log) {
          _scrollFocusedEnvPanel(down: false);
        }
      });
      return true;
    }
    if (key == LogicalKey.pageDown) {
      if (envFocus == FocusPanelEnv.status || envFocus == FocusPanelEnv.log) {
        setState(() => _scrollFocusedEnvPanel(down: true, lines: 10));
        return true;
      }
    }
    if (key == LogicalKey.pageUp) {
      if (envFocus == FocusPanelEnv.status || envFocus == FocusPanelEnv.log) {
        setState(() => _scrollFocusedEnvPanel(down: false, lines: 10));
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
        _reloadRunLists();
        _appendLogs(result.lines);
      });
      return true;
    }
    if (ch == '?') {
      setState(() {
        _appendLog(
          'Keys: 1 Env | 2 Run | q quit | Tab focus | Enter switch | s sync | d doctor | r refresh',
        );
      });
      return true;
    }

    return false;
  }

  bool _onRunKey(KeyboardEvent event) {
    final key = event.logicalKey;
    final ch = event.character?.toLowerCase();

    if (key == LogicalKey.escape && newSessionPicker) {
      setState(() => _closeNewSessionPicker(focus: FocusPanelRun.sessions));
      return true;
    }

    if (ch == 'n' && !newSessionPicker) {
      setState(_openNewSessionPicker);
      return true;
    }

    if (newSessionPicker) {
      return _onNewSessionPickerKey(event);
    }

    if (event.character == '[' ||
        (key == LogicalKey.arrowLeft && runFocus == FocusPanelRun.sessions)) {
      setState(() {
        sessions.selectPrevious();
        _ensureSessionVisible();
      });
      return true;
    }
    if (event.character == ']' ||
        (key == LogicalKey.arrowRight && runFocus == FocusPanelRun.sessions)) {
      setState(() {
        sessions.selectNext();
        _ensureSessionVisible();
      });
      return true;
    }

    if (key == LogicalKey.arrowDown || event.character == 'j') {
      if (runFocus == FocusPanelRun.sessions && sessions.hasSessions) {
        setState(() {
          sessions.selectNext();
          _ensureSessionVisible();
        });
        return true;
      }
    }
    if (key == LogicalKey.arrowUp || event.character == 'k') {
      if (runFocus == FocusPanelRun.sessions && sessions.hasSessions) {
        setState(() {
          sessions.selectPrevious();
          _ensureSessionVisible();
        });
        return true;
      }
    }

    if (event.character == 'h' || key == LogicalKey.arrowLeft) {
      if (runFocus == FocusPanelRun.terminal) {
        setState(() => runFocus = FocusPanelRun.sessions);
        return true;
      }
    }
    if (event.character == 'l' || key == LogicalKey.arrowRight) {
      if (runFocus == FocusPanelRun.sessions && sessions.hasSessions) {
        setState(() => runFocus = FocusPanelRun.terminal);
        return true;
      }
    }

    if (key == LogicalKey.enter) {
      if (runFocus == FocusPanelRun.sessions && sessions.hasSessions) {
        setState(() => runFocus = FocusPanelRun.terminal);
        return true;
      }
    }

    if (ch == 'x') {
      sessions.closeActive().then((_) {
        setState(() {
          _appendLog('Session closed');
          if (!sessions.hasSessions) {
            runFocus = FocusPanelRun.sessions;
          }
        });
      });
      return true;
    }
    if (ch == '?') {
      setState(() {
        _appendLog(
          'Run: n new session | Tab focus | jk/[ ] sessions | Enter terminal | '
          'x close | Ctrl+O leave terminal | Esc cancel picker | 1 Env',
        );
      });
      return true;
    }

    return false;
  }

  bool _onExtraArgsPromptKey(KeyboardEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKey.escape) {
      setState(_cancelExtraArgsPrompt);
      return true;
    }
    if (key == LogicalKey.enter) {
      final args = parseCliArgs(extraArgsDraft);
      _launchSelectedAction(extraArgs: args);
      return true;
    }
    if (key == LogicalKey.backspace) {
      if (extraArgsDraft.isEmpty) {
        return true;
      }
      setState(() {
        extraArgsDraft = extraArgsDraft.substring(0, extraArgsDraft.length - 1);
      });
      return true;
    }
    final ch = event.character;
    if (ch != null &&
        ch.isNotEmpty &&
        !event.isControlPressed &&
        !event.isAltPressed &&
        ch != '\n' &&
        ch != '\r') {
      setState(() => extraArgsDraft += ch);
      return true;
    }
    return true;
  }

  bool _onNewSessionPickerKey(KeyboardEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKey.escape) {
      setState(() => _closeNewSessionPicker(focus: FocusPanelRun.sessions));
      return true;
    }

    if (event.character == 'h' || key == LogicalKey.arrowLeft) {
      if (runFocus == FocusPanelRun.actions) {
        setState(() => runFocus = FocusPanelRun.targets);
        return true;
      }
    }
    if (event.character == 'l' || key == LogicalKey.arrowRight) {
      if (runFocus == FocusPanelRun.targets) {
        setState(() => runFocus = FocusPanelRun.actions);
        return true;
      }
    }

    if (key == LogicalKey.arrowDown || event.character == 'j') {
      setState(() {
        if (runFocus == FocusPanelRun.targets && targets.isNotEmpty) {
          targetCursor = (targetCursor + 1).clamp(0, targets.length - 1);
          _reloadActionsForSelectedTarget();
          _ensureTargetVisible();
          _ensureActionVisible();
        } else if (runFocus == FocusPanelRun.actions && actions.isNotEmpty) {
          actionCursor = (actionCursor + 1).clamp(0, actions.length - 1);
          _ensureActionVisible();
        }
      });
      return true;
    }
    if (key == LogicalKey.arrowUp || event.character == 'k') {
      setState(() {
        if (runFocus == FocusPanelRun.targets && targets.isNotEmpty) {
          targetCursor = (targetCursor - 1).clamp(0, targets.length - 1);
          _reloadActionsForSelectedTarget();
          _ensureTargetVisible();
          _ensureActionVisible();
        } else if (runFocus == FocusPanelRun.actions && actions.isNotEmpty) {
          actionCursor = (actionCursor - 1).clamp(0, actions.length - 1);
          _ensureActionVisible();
        }
      });
      return true;
    }

    if (key == LogicalKey.enter) {
      if (runFocus == FocusPanelRun.actions ||
          runFocus == FocusPanelRun.targets) {
        _launchSelectedAction();
        return true;
      }
    }

    final ch = event.character?.toLowerCase();
    if (ch == 'a') {
      setState(_openExtraArgsPrompt);
      return true;
    }
    if (ch == '?') {
      setState(() {
        _appendLog(
          'New session: Tab/hl panels | jk select | Enter start | '
          'a extra args | Esc cancel',
        );
      });
      return true;
    }

    return false;
  }

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final runHint = mode != TuiMode.run
        ? null
        : newSessionPicker
            ? 'New session — Enter start  a +args  Esc cancel  Tab panels'
            : _terminalCapturesKeys
                ? 'Terminal focus — keys → PTY  Ctrl+O leave  Ctrl+C interrupt'
                : runFocus == FocusPanelRun.terminal
                    ? 'Terminal idle — Tab/h leave  x close  j/k sessions'
                    : 'n new  Tab focus  jk/[ ] sessions  Enter/l terminal  '
                        'x close  (Ctrl+O leave PTY)';

    final body = Container(
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
          ModeBar(mode: mode),
          const SizedBox(height: 1),
          if (mode == TuiMode.env) ..._envBody() else ..._runBody(),
          FooterHelp(
            busy: busy,
            confirmPending: confirmPending,
            hintOverride: quitConfirmPending != null
                ? 'Quit with open sessions? [y]es / [n]o'
                : runHint,
          ),
        ],
      ),
    );

    Component content = body;
    if (extraArgsPrompt && targets.isNotEmpty && actions.isNotEmpty) {
      final targetId = targets[targetCursor].id;
      final actionId = actions[actionCursor].id;
      content = Stack(
        fit: StackFit.expand,
        children: [
          body,
          ExtraArgsPopup(
            title: 'Extra args — $targetId/$actionId',
            commandLine: _commandPreviewWithDraft(targetId, actionId),
          ),
        ],
      );
    }

    return Focusable(
      focused: !_terminalCapturesKeys,
      onKeyEvent: _onKey,
      child: content,
    );
  }

  /// Base resolved command + live draft (spaces / partial tokens).
  String _commandPreviewWithDraft(String targetId, String actionId) {
    final base = bridge.previewActionCommand(
      targetId: targetId,
      actionId: actionId,
    );
    final draft = extraArgsDraft;
    if (draft.isEmpty) {
      return base;
    }
    return '$base $draft';
  }

  /// Nocterm [Row]/[Column] + [Expanded] does not tighten the cross axis on
  /// flex children (`stretch` only applies to non-flex). [SizedBox.expand]
  /// forces min==max to the parent's max so [PanelFrame] fills the slot.
  Component _fillSlot(Component child) => SizedBox.expand(child: child);

  List<Component> _envBody() {
    return [
      Expanded(
        flex: 3,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: _fillSlot(
                ProfilesPanel(
                  profiles: profiles,
                  activeProfile: activeProfile,
                  cursor: profileCursor,
                  focused: envFocus == FocusPanelEnv.profiles,
                  scrollController: profileScroll,
                ),
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              flex: 3,
              child: _fillSlot(
                EnvironmentsPanel(
                  environments: environments,
                  activeEnvironment: activeEnvironment,
                  cursor: envCursor,
                  focused: envFocus == FocusPanelEnv.environments,
                  scrollController: envScroll,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 2,
        child: _fillSlot(
          StatusPanel(
            activeProfile: activeProfile,
            activeEnvironment: activeEnvironment,
            doctorLines: doctorLines,
            focused: envFocus == FocusPanelEnv.status,
            busy: busy,
            scrollController: statusScroll,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: _fillSlot(
          LogPanel(
            logs: logs,
            focused: envFocus == FocusPanelEnv.log,
            scrollController: logScroll,
          ),
        ),
      ),
    ];
  }

  /// Shared Run-mode split so Sessions and Targets sidebars match width.
  static const int _runSidebarFlex = 1;
  static const int _runMainFlex = 4;

  List<Component> _runBody() {
    if (newSessionPicker) {
      return [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: _runSidebarFlex,
                child: _fillSlot(
                  TargetsPanel(
                    targets: targets,
                    cursor: targetCursor,
                    focused: runFocus == FocusPanelRun.targets,
                    scrollController: targetScroll,
                  ),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                flex: _runMainFlex,
                child: _fillSlot(
                  ActionsPanel(
                    actions: actions,
                    cursor: actionCursor,
                    focused: runFocus == FocusPanelRun.actions,
                    scrollController: actionScroll,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: _runSidebarFlex,
              child: _fillSlot(
                SessionTabsPanel(
                  sessions: sessions.sessions,
                  activeIndex: sessions.activeIndex,
                  focused: runFocus == FocusPanelRun.sessions,
                  scrollController: sessionScroll,
                ),
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              flex: _runMainFlex,
              child: _fillSlot(
                SessionTerminalPanel(
                  session: sessions.activeSession,
                  focused: runFocus == FocusPanelRun.terminal,
                  onDetach: () {
                    setState(() => runFocus = FocusPanelRun.sessions);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
