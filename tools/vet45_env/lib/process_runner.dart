import 'dart:io';

import 'executable_resolver.dart';

/// Abstraction over [Process.start] for tests.
abstract class ProcessRunner {
  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool inheritStdio = true,
  });
}

class IoProcessRunner implements ProcessRunner {
  @override
  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool inheritStdio = true,
  }) async {
    final resolved = resolveExecutable(executable);
    final process = await Process.start(
      resolved,
      arguments,
      runInShell: useShellOnWindows(resolved),
      workingDirectory: workingDirectory,
      environment: environment,
      mode: inheritStdio ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
    );
    return process.exitCode;
  }
}
