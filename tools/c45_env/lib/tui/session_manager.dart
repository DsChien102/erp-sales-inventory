import 'package:nocterm/nocterm.dart';

import '../action_runner.dart';
import 'session_emulator.dart';

/// One embedded PTY session in the Run mode TUI.
class TuiSession {
  TuiSession({
    required this.id,
    required this.plan,
    required this.controller,
    required this.emulator,
  });

  final String id;
  final ActionLaunchPlan plan;
  final PtyController controller;

  /// Private screen buffer for this session's stdout/stderr.
  final SessionEmulator emulator;

  int? exitCode;

  String get label => plan.label;

  bool get isRunning => controller.isRunning;
}

/// Manages multiple [TuiSession]s (cap [maxSessions]).
class SessionManager {
  SessionManager({
    this.maxSessions = 8,
    PtyController Function(ActionLaunchPlan plan)? createController,
    this.onSessionExit,
  }) : _createController = createController ?? _defaultController;

  static const defaultMaxSessions = 8;

  final int maxSessions;
  final PtyController Function(ActionLaunchPlan plan) _createController;

  /// Called after a session process exits (status already updated).
  final void Function(TuiSession session)? onSessionExit;

  final List<TuiSession> sessions = [];
  int activeIndex = 0;
  int _seq = 0;

  static PtyController _defaultController(ActionLaunchPlan plan) {
    return PtyController(
      command: plan.command,
      arguments: plan.args,
      workingDirectory: plan.workingDirectory,
      environment: plan.environment,
    );
  }

  TuiSession? get activeSession {
    if (sessions.isEmpty) {
      return null;
    }
    return sessions[activeIndex.clamp(0, sessions.length - 1)];
  }

  /// Opens a new session. Throws [StateError] if at capacity.
  TuiSession open(ActionLaunchPlan plan) {
    if (sessions.length >= maxSessions) {
      throw StateError(
        'Session limit reached ($maxSessions). Close one with x first.',
      );
    }
    _seq += 1;
    final id = '$_seq';
    final controller = _createController(plan);
    final emulator = SessionEmulator();
    // Keep feeding this session's buffer for the whole lifetime (also when
    // another session is visible).
    controller.addOutputCallback(emulator.write);
    final session = TuiSession(
      id: id,
      plan: plan,
      controller: controller,
      emulator: emulator,
    );
    controller.addExitCallback((code) {
      session.exitCode = code;
      onSessionExit?.call(session);
    });
    sessions.add(session);
    activeIndex = sessions.length - 1;
    return session;
  }

  void selectIndex(int index) {
    if (sessions.isEmpty) {
      return;
    }
    activeIndex = index.clamp(0, sessions.length - 1);
  }

  void selectPrevious() {
    if (sessions.length < 2) {
      return;
    }
    activeIndex = (activeIndex - 1 + sessions.length) % sessions.length;
  }

  void selectNext() {
    if (sessions.length < 2) {
      return;
    }
    activeIndex = (activeIndex + 1) % sessions.length;
  }

  Future<void> closeActive() async {
    if (sessions.isEmpty) {
      return;
    }
    await closeAt(activeIndex);
  }

  Future<void> closeAt(int index) async {
    if (index < 0 || index >= sessions.length) {
      return;
    }
    final session = sessions.removeAt(index);
    session.controller.removeOutputCallback(session.emulator.write);
    if (session.controller.isRunning) {
      session.controller.kill();
    }
    await session.controller.dispose();
    if (sessions.isEmpty) {
      activeIndex = 0;
    } else if (activeIndex >= sessions.length) {
      activeIndex = sessions.length - 1;
    } else if (index < activeIndex) {
      activeIndex -= 1;
    }
  }

  Future<void> closeAll() async {
    while (sessions.isNotEmpty) {
      await closeAt(sessions.length - 1);
    }
  }

  bool get hasRunningSession => sessions.any((s) => s.isRunning);

  bool get hasSessions => sessions.isNotEmpty;
}
