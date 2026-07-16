import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/config_init_service.dart';
import 'package:vet45_env/manifest.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late Directory templates;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_config_init_');
    templates = Directory('${root.path}/tools/vet45_env/templates/config');
    await _copyBundledTemplates(templates);
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: vet45\n');
    writeTestWorkspace(root);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('init scaffolds secrets from templates', () async {
    // Remove secrets dir created by writeTestWorkspace so init can create it.
    final secrets = Directory('${root.path}/config/secrets');
    if (secrets.existsSync()) {
      secrets.deleteSync(recursive: true);
    }

    final service = ConfigInitService(repoRoot: root);
    expect(service.hasWorkspace, isTrue);
    expect(service.isInitialized, isFalse);

    final result = await service.init();
    expect(result.created, isNotEmpty);
    expect(
      File('${root.path}/config/secrets/development.env.example').existsSync(),
      isTrue,
    );
    expect(File('${root.path}/vet45.workspace.json').existsSync(), isTrue);

    final manifest = EnvManifest.load(root);
    expect(manifest.defaultEnvironmentId, 'local');
  });

  test('init refuses when secrets already initialized', () async {
    final service = ConfigInitService(repoRoot: root);
    // secrets/ already exists from writeTestWorkspace
    expect(
      () => service.init(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already initialized'),
        ),
      ),
    );
  });

  test('init --force refreshes scaffold but keeps filled secrets', () async {
    final service = ConfigInitService(repoRoot: root);
    // Ensure examples exist via init --force first.
    await service.init(force: true);

    final secretsFile = File('${root.path}/config/secrets/development.env');
    secretsFile.writeAsStringSync('SUPABASE_URL=https://filled.supabase.co\n');

    final example = File('${root.path}/config/secrets/development.env.example');
    example.writeAsStringSync('# stale example\n');

    final result = await service.init(force: true);
    expect(result.created, contains('secrets/development.env.example'));
    expect(secretsFile.readAsStringSync(), contains('filled.supabase.co'));
  });

  test('init fails without workspace manifest', () async {
    File('${root.path}/vet45.workspace.json').deleteSync();
    final service = ConfigInitService(repoRoot: root);
    Directory('${root.path}/config/secrets').deleteSync(recursive: true);
    expect(
      () => service.init(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('vet45.workspace.json'),
        ),
      ),
    );
  });
}

Future<void> _copyBundledTemplates(Directory dest) async {
  final source = Directory(
    '${Directory.current.path}/templates/config',
  );
  if (!source.existsSync()) {
    final fromCwd = Directory('tools/vet45_env/templates/config');
    await _copyTree(fromCwd, dest);
    return;
  }
  await _copyTree(source, dest);
}

Future<void> _copyTree(Directory source, Directory dest) async {
  dest.createSync(recursive: true);
  await for (final entity in source.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final relative = entity.path.substring(source.path.length + 1);
    final target = File('${dest.path}/$relative');
    target.parent.createSync(recursive: true);
    await target.writeAsBytes(await entity.readAsBytes());
  }
}
