import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_supabase_migrate/generate_migration_service.dart';
import 'package:vet45_supabase_migrate/migration_policy.dart';
import 'package:vet45_supabase_migrate/migration_registry.dart';
import 'package:vet45_supabase_migrate/schema_lock.dart';

void main() {
  late Directory tempDir;
  late GenerateMigrationService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vet45_generate_migration_');
    service = GenerateMigrationService();
    Directory('${tempDir.path}/supabase/migrations').createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String moduleFunctionPath(String module, String name) =>
      'modules/$module/infrastructure/supabase/sql/functions/$name.sql';

  String sharedFunctionPath(String schema, String name) =>
      'supabase/sql/$schema/functions/$name.sql';

  void writeSource(String relativePath, String sql) {
    File('${tempDir.path}/$relativePath')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(sql);
  }

  void deleteSource(String relativePath) {
    File('${tempDir.path}/$relativePath').deleteSync();
  }

  String function(String qualifiedName, {String args = '', String body = '1'}) =>
      '''
create or replace function $qualifiedName($args)
returns int language sql as \$\$ select $body \$\$;
''';

  List<String> migrationNames() => Directory('${tempDir.path}/supabase/migrations')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .toList()
    ..sort();

  String readMigration(String name) =>
      File('${tempDir.path}/supabase/migrations/$name').readAsStringSync();

  SchemaLock readLock() =>
      SchemaLock.load(File('${tempDir.path}/$schemaLockRelativePath'));

  GenerateMigrationResult generate(
    String intent, {
    String startTimestamp = '20990101001',
    bool dryRun = false,
  }) {
    return service.generate(
      GenerateMigrationOptions(
        repoRoot: tempDir,
        intent: intent,
        startTimestamp: startTimestamp,
        dryRun: dryRun,
      ),
    );
  }

  test('generates migration for new module and shared functions', () {
    final catalogSource = function('catalog.search_products', args: 'p_query text');
    final publicSource = function('public.current_tenant_id');
    writeSource(moduleFunctionPath('catalog', 'search_products'), catalogSource);
    writeSource(sharedFunctionPath('public', 'current_tenant_id'), publicSource);

    final result = generate('first_functions');

    expect(result.migration?.fileName, '20990101001_first_functions.sql');
    expect(migrationNames(), ['20990101001_first_functions.sql']);

    final sql = readMigration('20990101001_first_functions.sql');
    expect(sql, startsWith('''
-- Kind: generated
-- Intent: first_functions
-- Touches: catalog.search_products, public.current_tenant_id
'''));
    expect(sql, contains('-- region: functions'));
    expect(sql, contains(catalogSource.trimRight()));
    expect(sql, contains(publicSource.trimRight()));
    expect(
      sql.indexOf('catalog.search_products('),
      lessThan(sql.indexOf('public.current_tenant_id(')),
    );
  });

  test('lock stores source path, hash, signatures and last migration', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      '${function('catalog.search_products', args: 'p_query text')}\n'
      '${function('catalog.search_products', args: 'p_query text, p_limit int')}',
    );

    generate('catalog_search');

    final entry = readLock().entries['catalog.search_products']!;
    expect(entry.sourcePath, moduleFunctionPath('catalog', 'search_products'));
    expect(entry.hash, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
    expect(entry.signatures, [
      'catalog.search_products(p_query text)',
      'catalog.search_products(p_query text, p_limit int)',
    ]);
    expect(entry.lastMigration, '20990101001_catalog_search.sql');
  });

  test('rerun without source changes generates nothing', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );
    generate('first');
    final lockBefore =
        File('${tempDir.path}/$schemaLockRelativePath').readAsStringSync();

    final result = generate('second', startTimestamp: '20990101002');

    expect(result.migration, isNull);
    expect(migrationNames(), ['20990101001_first.sql']);
    expect(
      File('${tempDir.path}/$schemaLockRelativePath').readAsStringSync(),
      lockBefore,
    );
  });

  test('only changed functions are included in the next migration', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );
    writeSource(
      moduleFunctionPath('catalog', 'create_product'),
      function('catalog.create_product'),
    );
    generate('first');

    writeSource(
      moduleFunctionPath('catalog', 'create_product'),
      function('catalog.create_product', body: '2'),
    );
    final result = generate('tweak_create', startTimestamp: '20990101002');

    expect(result.migration?.touches, ['catalog.create_product']);
    final sql = readMigration('20990101002_tweak_create.sql');
    expect(sql, contains('-- Touches: catalog.create_product\n'));
    expect(sql, isNot(contains('catalog.search_products')));

    final lock = readLock();
    expect(
      lock.entries['catalog.create_product']!.lastMigration,
      '20990101002_tweak_create.sql',
    );
    expect(
      lock.entries['catalog.search_products']!.lastMigration,
      '20990101001_first.sql',
    );
  });

  test('added overload is regenerated', () {
    final path = moduleFunctionPath('catalog', 'search_products');
    writeSource(path, function('catalog.search_products'));
    generate('first');

    writeSource(
      path,
      '${function('catalog.search_products')}\n'
      '${function('catalog.search_products', args: 'p_query text')}',
    );
    final result = generate('overload', startTimestamp: '20990101002');

    expect(result.migration?.touches, ['catalog.search_products']);
    expect(readLock().entries['catalog.search_products']!.signatures, hasLength(2));
  });

  test('dry run writes neither migration nor lock', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );

    final result = generate('first', dryRun: true);

    expect(result.migration?.fileName, '20990101001_first.sql');
    expect(result.written, isNull);
    expect(migrationNames(), isEmpty);
    expect(File('${tempDir.path}/$schemaLockRelativePath').existsSync(), isFalse);
  });

  test('fails when module function schema differs from module name', () {
    writeSource(
      moduleFunctionPath('catalog', 'create_partner'),
      function('partner.create_partner'),
    );

    expect(
      () => generate('wrong_schema'),
      throwsA(
        isA<SchemaSourceException>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains(moduleFunctionPath('catalog', 'create_partner')),
            contains('schema "catalog"'),
          ),
        ),
      ),
    );
    expect(migrationNames(), isEmpty);
  });

  test('fails when shared function schema differs from its folder', () {
    writeSource(
      sharedFunctionPath('public', 'enqueue'),
      function('messaging.enqueue'),
    );

    expect(() => generate('wrong_schema'), throwsA(isA<SchemaSourceException>()));
  });

  test('fails when two files define the same object', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );
    writeSource(
      sharedFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );

    expect(
      () => generate('duplicate'),
      throwsA(
        isA<SchemaSourceException>().having(
          (e) => e.toString(),
          'message',
          contains('catalog.search_products'),
        ),
      ),
    );
  });

  test('fails when file name does not match function name', () {
    writeSource(
      moduleFunctionPath('catalog', 'search'),
      function('catalog.search_products'),
    );

    expect(() => generate('misnamed'), throwsA(isA<SchemaSourceException>()));
  });

  test('fails when a file defines no function', () {
    writeSource(moduleFunctionPath('catalog', 'empty'), '-- nothing yet\n');

    expect(() => generate('empty'), throwsA(isA<SchemaSourceException>()));
  });

  test('fails when a locked function source is deleted', () {
    final path = moduleFunctionPath('catalog', 'search_products');
    writeSource(path, function('catalog.search_products'));
    generate('first');

    deleteSource(path);

    expect(
      () => generate('removed', startTimestamp: '20990101002'),
      throwsA(
        isA<SchemaSourceException>().having(
          (e) => e.toString(),
          'message',
          contains('catalog.search_products'),
        ),
      ),
    );
    expect(migrationNames(), ['20990101001_first.sql']);
  });

  test('fails when a locked overload is removed or its signature changes', () {
    final path = moduleFunctionPath('catalog', 'search_products');
    writeSource(path, function('catalog.search_products', args: 'p_query text'));
    generate('first');

    writeSource(path, function('catalog.search_products', args: 'p_query varchar'));

    expect(
      () => generate('signature', startTimestamp: '20990101002'),
      throwsA(
        isA<SchemaSourceException>().having(
          (e) => e.toString(),
          'message',
          contains('catalog.search_products(p_query text)'),
        ),
      ),
    );
  });

  test('changing parameter defaults or keyword case keeps the overload', () {
    final path = moduleFunctionPath('catalog', 'search_products');
    writeSource(
      path,
      function('catalog.search_products', args: "p_tags text[] default array['a', 'b']"),
    );
    generate('first');

    writeSource(
      path,
      function('catalog.search_products', args: 'p_tags TEXT[] = null'),
    );
    final result = generate('new_default', startTimestamp: '20990101002');

    expect(result.migration?.touches, ['catalog.search_products']);
    expect(
      readLock().entries['catalog.search_products']!.signatures,
      ['catalog.search_products(p_tags TEXT[] = null)'],
    );
  });

  test('line endings do not affect change detection', () {
    final path = moduleFunctionPath('catalog', 'search_products');
    writeSource(path, function('catalog.search_products'));
    generate('first');

    writeSource(
      path,
      function('catalog.search_products').replaceAll('\n', '\r\n'),
    );

    expect(generate('crlf', startTimestamp: '20990101002').migration, isNull);
  });

  test('rejects intent that is not a snake_case slug', () {
    expect(() => generate('Bad Intent'), throwsArgumentError);
  });

  test('generated migration passes migration policy', () {
    writeSource(
      moduleFunctionPath('catalog', 'search_products'),
      function('catalog.search_products'),
    );
    final result = generate('first');

    final violations = MigrationPolicyVerifier().verifyFile(
      fileName: result.migration!.fileName,
      sql: result.migration!.sql,
      registry: MigrationRegistry.empty(),
    );

    expect(violations, isEmpty);
  });
}
