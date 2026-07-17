import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/process_runner.dart';
import 'package:vet45_env/secrets_loader.dart';
import 'package:vet45_env/supabase_delegate_service.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;
  late _RecordingProcessRunner process;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_supabase_delegate_');
    writeTestWorkspace(root);
    writeDotEnv(
      File('${root.path}/config/default/auth.env'),
      {'SUPABASE_ACCESS_TOKEN': 'sbp_test_token'},
    );
    manifest = EnvManifest.load(root);
    process = _RecordingProcessRunner();
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('runs supabase with profile token in environment', () async {
    final service = SupabaseDelegateService(
      manifest: manifest,
      processRunner: process,
      warnWhenTokenMissing: false,
    );

    final code = await service.run(
      testContext(manifest, 'local'),
      ['migration', 'list'],
    );

    expect(code, 0);
    expect(process.invocations, hasLength(1));
    expect(process.invocations.first.executable, 'supabase');
    expect(process.invocations.first.arguments, ['migration', 'list']);
    expect(
      process.invocations.first.environment?['SUPABASE_ACCESS_TOKEN'],
      'sbp_test_token',
    );
    expect(
      process.invocations.first.workingDirectory,
      manifest.rootDir.path,
    );
  });

  test('requires at least one supabase argument', () async {
    final service = SupabaseDelegateService(
      manifest: manifest,
      processRunner: process,
      warnWhenTokenMissing: false,
    );

    expect(
      () => service.run(testContext(manifest, 'local'), []),
      throwsArgumentError,
    );
  });
}

class _RecordingProcessRunner implements ProcessRunner {
  final invocations = <_Invocation>[];

  @override
  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool inheritStdio = true,
  }) async {
    invocations.add(
      _Invocation(
        executable: executable,
        arguments: List.unmodifiable(arguments),
        workingDirectory: workingDirectory,
        environment: environment == null ? null : Map.unmodifiable(environment),
      ),
    );
    return 0;
  }
}

class _Invocation {
  _Invocation({
    required this.executable,
    required this.arguments,
    this.workingDirectory,
    this.environment,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String>? environment;
}
