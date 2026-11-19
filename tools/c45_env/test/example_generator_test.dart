import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_env/example_generator.dart';

import 'test_manifest_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('c45_example_gen_');
    writeTestWorkspace(
      root,
      profileIds: const [],
      writeActive: false,
      includeAdmin: true,
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('aggregates sourceKey with target-prefixed comments', () {
    final gen = ExampleGenerator(repoRoot: root);
    final body = gen.renderProfileExample(environmentId: 'development');
    expect(body, contains('# erp: Supabase project URL for ERP'));
    expect(body, contains('# admin: Supabase project URL for Admin'));
    expect(body, contains('# worker: Supabase project URL for worker'));
    expect(body, contains('SUPABASE_URL='));
    expect(body, contains('# erp: Supabase anon key for ERP'));
    expect(body, contains('# admin: Supabase anon key for Admin'));
    expect(body, contains('SUPABASE_ANON_KEY='));
    expect(body, contains('WORKER_LOG_LEVEL=WARNING'));
    expect(body, contains('# profile: Optional project ref'));
    expect(body, isNot(contains('APP_ENV=')));
  });

  test('local comments out KEY= lines but keeps descriptions', () {
    final gen = ExampleGenerator(repoRoot: root);
    final body = gen.renderProfileExample(environmentId: 'local');
    expect(body, contains('# erp: Supabase project URL for ERP'));
    expect(body, contains('# SUPABASE_URL='));
    expect(body, isNot(contains(RegExp(r'^SUPABASE_URL=', multiLine: true))));
  });

  test('deploy example uses deploy: descriptions', () {
    final gen = ExampleGenerator(repoRoot: root);
    final body = gen.renderDeployExample();
    expect(body, contains('# deploy: ASC issuer ID'));
    expect(body, contains('APP_STORE_CONNECT_ISSUER_ID='));
  });

  test('missing description fails check', () {
    final target = File('${root.path}/apps/erp/c45.target.json');
    final raw = target.readAsStringSync().replaceFirst(
      '"description": "Supabase anon key for ERP"',
      '"description": ""',
    );
    target.writeAsStringSync(raw);
    final gen = ExampleGenerator(repoRoot: root);
    expect(gen.missingDescriptions(), contains('erp.SUPABASE_ANON_KEY'));
    expect(() => gen.ensureDescriptionsPresent(), throwsStateError);
  });
}
