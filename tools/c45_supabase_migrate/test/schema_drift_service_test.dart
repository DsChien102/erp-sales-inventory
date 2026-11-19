import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_supabase_migrate/apply_dev_service.dart';
import 'package:c45_supabase_migrate/schema_drift_service.dart';

class DriftFakeExecutor implements SqlExecutor {
  DriftFakeExecutor(this.responses);

  /// Maps a substring of the query to rows returned.
  final Map<String, List<Map<String, Object?>>> responses;
  final queries = <String>[];

  @override
  Future<void> execute(String sql) async {}

  @override
  Future<List<Map<String, Object?>>> query(String sql) async {
    queries.add(sql);
    for (final entry in responses.entries) {
      if (sql.contains(entry.key)) {
        return entry.value;
      }
    }
    return const [];
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('c45_schema_drift_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeFunction(String name, String createSql) {
    final path =
        'modules/catalog/infrastructure/supabase/sql/functions/$name.sql';
    File('${tempDir.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(createSql);
  }

  const sourceSql =
      'create or replace function catalog.search_products()\n'
      'returns int language sql as \$\$ select 1 \$\$;\n';

  const dbDef =
      'CREATE OR REPLACE FUNCTION catalog.search_products()\n'
      ' RETURNS integer\n'
      ' LANGUAGE sql\n'
      'AS \$function\$\n'
      ' select 1 \n'
      '\$function\$\n';

  test('passes when DB definition matches source body', () async {
    writeFunction('search_products', sourceSql);
    final executor = DriftFakeExecutor({
      "proname = 'search_products'": [
        {
          'def': dbDef,
          'args': '',
        },
      ],
    });
    final result = await SchemaDriftService(executor: executor).check(tempDir);
    expect(result.isClean, isTrue);
    expect(result.matched, ['catalog.search_products']);
    expect(result.mismatches, isEmpty);
  });

  test('reports missing object when DB has no matching function', () async {
    writeFunction('search_products', sourceSql);
    final executor = DriftFakeExecutor({});
    final result = await SchemaDriftService(executor: executor).check(tempDir);
    expect(result.isClean, isFalse);
    expect(result.mismatches.single.qualifiedName, 'catalog.search_products');
    expect(result.mismatches.single.kind, SchemaDriftKind.missing);
  });

  test('reports body mismatch when function body differs', () async {
    writeFunction('search_products', sourceSql);
    final executor = DriftFakeExecutor({
      "proname = 'search_products'": [
        {
          'def': dbDef.replaceAll('select 1', 'select 2'),
          'args': '',
        },
      ],
    });
    final result = await SchemaDriftService(executor: executor).check(tempDir);
    expect(result.isClean, isFalse);
    expect(result.mismatches.single.kind, SchemaDriftKind.bodyMismatch);
  });

  test('reports nothing when there are no declarative sources', () async {
    final executor = DriftFakeExecutor({});
    final result = await SchemaDriftService(executor: executor).check(tempDir);
    expect(result.isClean, isTrue);
    expect(result.matched, isEmpty);
    expect(executor.queries, isEmpty);
  });
}
