import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_supabase_migrate/adopt_schema_service.dart';
import 'package:c45_supabase_migrate/generate_migration_service.dart';
import 'package:c45_supabase_migrate/migration_registry.dart';
import 'package:c45_supabase_migrate/schema_lock.dart';

void main() {
  late Directory tempDir;
  late AdoptSchemaService adopt;
  late GenerateMigrationService generate;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('c45_adopt_schema_');
    adopt = AdoptSchemaService();
    generate = GenerateMigrationService();
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

  void writeMigration(String name, String sql) {
    File('${tempDir.path}/supabase/migrations/$name')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(sql);
  }

  void writeRegistry(String yaml) {
    File('${tempDir.path}/$registryRelativePath')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(yaml);
  }

  MigrationRegistry readRegistry() =>
      MigrationRegistry.load(File('${tempDir.path}/$registryRelativePath'));

  SchemaLock readLock() =>
      SchemaLock.load(File('${tempDir.path}/$schemaLockRelativePath'));

  String readSource(String relativePath) =>
      File('${tempDir.path}/$relativePath').readAsStringSync();

  String function(
    String qualifiedName, {
    String args = '',
    String body = '1',
  }) =>
      '''
create or replace function $qualifiedName($args)
returns int language sql as \$\$ select $body \$\$;
''';

  test('adopts one object from REGISTRY into module source + lock', () {
    Directory('${tempDir.path}/modules/catalog').createSync(recursive: true);
    const migration = '20260805003_catalog_search_products_summary_counts.sql';
    final overloadA = function(
      'catalog.search_products',
      args: 'p_query text',
      body: '1',
    );
    final overloadB = function(
      'catalog.search_products',
      args: 'p_query text, p_limit int',
      body: '2',
    );
    writeMigration(
      migration,
      '-- Kind: patch\n$overloadA\n$overloadB\n'
      '${function('catalog.other_thing')}',
    );
    writeRegistry('''
catalog:
  search_products: $migration
  other_thing: $migration

bootstrap_grandfathered:
''');

    final result = adopt.adopt(
      AdoptSchemaOptions(
        repoRoot: tempDir,
        qualifiedName: 'catalog.search_products',
      ),
    );

    expect(result.adopted, ['catalog.search_products']);
    final source = readSource(moduleFunctionPath('catalog', 'search_products'));
    expect(source, contains(overloadA.trim()));
    expect(source, contains(overloadB.trim()));
    expect(source, isNot(contains('other_thing')));
    expect(
      readRegistry().ownerMigration(
        schema: 'catalog',
        functionName: 'search_products',
      ),
      isNull,
    );
    expect(
      readRegistry().ownerMigration(
        schema: 'catalog',
        functionName: 'other_thing',
      ),
      migration,
    );

    final entry = readLock().entries['catalog.search_products']!;
    expect(entry.sourcePath, moduleFunctionPath('catalog', 'search_products'));
    expect(entry.lastMigration, migration);
    expect(entry.hash, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
    expect(entry.signatures, [
      'catalog.search_products(p_query text)',
      'catalog.search_products(p_query text, p_limit int)',
    ]);

    final generated = generate.generate(
      GenerateMigrationOptions(
        repoRoot: tempDir,
        intent: 'should_be_empty',
        startTimestamp: '20990101001',
      ),
    );
    expect(generated.migration, isNull);
  });

  test('adopts whole module and leaves generate as no-op', () {
    Directory('${tempDir.path}/modules/catalog').createSync(recursive: true);
    const migrationA = '20260801001_catalog_a.sql';
    const migrationB = '20260801002_catalog_b.sql';
    writeMigration(migrationA, function('catalog.alpha', body: '10'));
    writeMigration(migrationB, function('catalog.beta', body: '20'));
    writeRegistry('''
catalog:
  alpha: $migrationA
  beta: $migrationB

bootstrap_grandfathered:
''');

    final result = adopt.adopt(
      AdoptSchemaOptions(repoRoot: tempDir, module: 'catalog'),
    );

    expect(result.adopted, ['catalog.alpha', 'catalog.beta']);
    expect(File('${tempDir.path}/${moduleFunctionPath('catalog', 'alpha')}')
        .existsSync(), isTrue);
    expect(File('${tempDir.path}/${moduleFunctionPath('catalog', 'beta')}')
        .existsSync(), isTrue);
    expect(readRegistry().schemas['catalog'], isNull);
    expect(readLock().entries['catalog.alpha']!.lastMigration, migrationA);
    expect(readLock().entries['catalog.beta']!.lastMigration, migrationB);

    final generated = generate.generate(
      GenerateMigrationOptions(
        repoRoot: tempDir,
        intent: 'should_be_empty',
        startTimestamp: '20990101001',
      ),
    );
    expect(generated.migration, isNull);
    expect(
      Directory('${tempDir.path}/supabase/migrations')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.contains('should_be_empty'))
          .toList(),
      isEmpty,
    );
  });

  test('writes shared sql root when module directory is absent', () {
    const migration = '20260801001_platform_helper.sql';
    writeMigration(migration, function('platform.helper'));
    writeRegistry('''
platform:
  helper: $migration

bootstrap_grandfathered:
''');

    adopt.adopt(
      AdoptSchemaOptions(
        repoRoot: tempDir,
        qualifiedName: 'platform.helper',
      ),
    );

    expect(
      File('${tempDir.path}/${sharedFunctionPath('platform', 'helper')}')
          .existsSync(),
      isTrue,
    );
    expect(
      readLock().entries['platform.helper']!.sourcePath,
      sharedFunctionPath('platform', 'helper'),
    );
  });

  test('fails clearly when object is missing from source migration', () {
    Directory('${tempDir.path}/modules/catalog').createSync(recursive: true);
    const migration = '20260801001_catalog_missing.sql';
    writeMigration(migration, function('catalog.other'));
    writeRegistry('''
catalog:
  search_products: $migration

bootstrap_grandfathered:
''');

    expect(
      () => adopt.adopt(
        AdoptSchemaOptions(
          repoRoot: tempDir,
          qualifiedName: 'catalog.search_products',
        ),
      ),
      throwsA(
        isA<AdoptSchemaException>().having(
          (error) => error.message,
          'message',
          contains('catalog.search_products not found in migration $migration'),
        ),
      ),
    );
  });

  test('fails when object is not in REGISTRY', () {
    expect(
      () => adopt.adopt(
        AdoptSchemaOptions(
          repoRoot: tempDir,
          qualifiedName: 'catalog.missing',
        ),
      ),
      throwsA(
        isA<AdoptSchemaException>().having(
          (error) => error.message,
          'message',
          contains('catalog.missing is not in REGISTRY.yaml'),
        ),
      ),
    );
  });
}
