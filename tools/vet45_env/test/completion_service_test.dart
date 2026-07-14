import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/completion_service.dart';
import 'package:vet45_env/manifest.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;
  late EnvManifest manifest;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_completion_');
    Directory('${root.path}/config/secrets').createSync(recursive: true);
    File('${root.path}/config/environments.json').writeAsStringSync(
      manifestWithEnv('''
{
  "local": {
    "description": "test local",
    "supabaseSource": "secrets",
    "targets": {
      "erp": {
        "flavor": "development",
        "envFile": "apps/erp/.env",
        "appEnv": "development"
      },
      "worker": {
        "envFile": "apps/messaging_worker/.env"
      }
    }
  }
}
'''),
    );
    File('${root.path}/config/profiles.json').writeAsStringSync('''
{
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "description": "Default",
      "secretsRoot": "config/secrets"
    },
    "acme": {
      "description": "Acme",
      "secretsRoot": "config/profiles/acme/secrets"
    }
  }
}
''');
    manifest = EnvManifest.load(root);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('bash completion includes commands and dynamic ids', () {
    final script = CompletionService(manifest: manifest).render('bash');
    expect(script, contains('complete -F _vet45 vet45'));
    expect(script, contains('switch'));
    expect(script, contains('acme'));
    expect(script, contains('local'));
  });

  test('zsh completion includes compdef and dynamic ids', () {
    final script = CompletionService(manifest: manifest).render('zsh');
    expect(script, contains('#compdef vet45'));
    expect(script, contains("'switch'"));
    expect(script, contains("'acme'"));
    expect(script, contains("'local'"));
  });

  test('unsupported shell throws', () {
    expect(
      () => CompletionService(manifest: manifest).render('fish'),
      throwsArgumentError,
    );
  });
}
