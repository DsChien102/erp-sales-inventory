import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/config_init_service.dart';
import 'package:vet45_env/manifest.dart';

void main() {
  late Directory root;
  late Directory templates;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_config_init_');
    templates = Directory('${root.path}/tools/vet45_env/templates/config');
    await _copyBundledTemplates(templates);
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: vet45\n');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('init scaffolds config from templates', () async {
    final service = ConfigInitService(repoRoot: root);
    expect(service.isInitialized, isFalse);

    final result = await service.init();
    expect(result.created, isNotEmpty);
    expect(File('${root.path}/config/environments.json').existsSync(), isTrue);
    expect(File('${root.path}/config/profiles.json').existsSync(), isTrue);
    expect(
      File('${root.path}/config/secrets/development.env.example').existsSync(),
      isTrue,
    );

    final manifest = EnvManifest.load(root);
    expect(manifest.defaultEnvironmentId, 'development');
  });

  test('init refuses when already initialized', () async {
    final service = ConfigInitService(repoRoot: root);
    await service.init();
    expect(
      () => service.init(),
      throwsA(isA<StateError>().having((e) => e.message, 'message', contains('already initialized'))),
    );
  });

  test('init --force refreshes scaffold but keeps filled secrets', () async {
    final service = ConfigInitService(repoRoot: root);
    await service.init();

    final secretsFile = File('${root.path}/config/secrets/development.env');
    secretsFile.writeAsStringSync('SUPABASE_URL=https://filled.supabase.co\n');

    final profiles = File('${root.path}/config/profiles.json');
    profiles.writeAsStringSync('{"stale": true}\n');

    final result = await service.init(force: true);
    expect(result.created, contains('profiles.json'));
    expect(secretsFile.readAsStringSync(), contains('filled.supabase.co'));
  });
}

Future<void> _copyBundledTemplates(Directory dest) async {
  final source = Directory(
    '${Directory.current.path}/templates/config',
  );
  if (!source.existsSync()) {
    // Running from repo root via melos / dart test in tools/vet45_env.
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
