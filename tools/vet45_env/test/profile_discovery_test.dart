import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_env/profile_discovery.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vet45_profile_discovery_');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('discovers profile dirs and skips deploy/_templates', () {
    writeTestWorkspace(
      root,
      profileIds: ['default', 'acme'],
    );
    final profiles = ProfileDiscovery(rootDir: root).discover();
    expect(profiles.keys, containsAll(['default', 'acme']));
    expect(profiles.containsKey('deploy'), isFalse);
    expect(profiles.containsKey('_templates'), isFalse);
    expect(profiles['acme']!.secretsRoot, '.vet45/profiles/acme');
  });

  test('returns empty when no profile dirs', () {
    writeTestWorkspace(
      root,
      profileIds: const [],
      writeActive: false,
    );
    expect(ProfileDiscovery(rootDir: root).discover(), isEmpty);
  });
}
