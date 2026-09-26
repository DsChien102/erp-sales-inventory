import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:vet45_supabase_migrate/schema_lock.dart';
import 'package:vet45_supabase_migrate/schema_lock_sync.dart';

String sha(String content) => 'sha256:${sha256.convert(utf8.encode(content))}';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vet45_lock_sync_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeSource(String relativePath, String sql) {
    File('${tempDir.path}/$relativePath')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(sql);
  }

  test('reports added changed and removed objects', () {
    const searchPath =
        'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql';
    const createPath =
        'modules/catalog/infrastructure/supabase/sql/functions/create_product.sql';
    const newPath =
        'modules/catalog/infrastructure/supabase/sql/functions/new_fn.sql';

    const createSql =
        'create or replace function catalog.create_product()\n'
        'returns int language sql as \$\$ select 1 \$\$;\n';
    const searchSql =
        'create or replace function catalog.search_products()\n'
        'returns int language sql as \$\$ select 2 \$\$;\n';
    const newSql =
        'create or replace function catalog.new_fn()\n'
        'returns int language sql as \$\$ select 1 \$\$;\n';

    writeSource(createPath, createSql);
    writeSource(searchPath, searchSql);
    writeSource(newPath, newSql);

    final lock = SchemaLock({
      'catalog.create_product': SchemaLockEntry(
        sourcePath: createPath,
        hash: sha(createSql),
        signatures: const ['catalog.create_product()'],
        lastMigration: '20990101001_old.sql',
      ),
      'catalog.search_products': const SchemaLockEntry(
        sourcePath: searchPath,
        hash: 'sha256:stale',
        signatures: ['catalog.search_products()'],
        lastMigration: '20990101001_old.sql',
      ),
      'catalog.gone': const SchemaLockEntry(
        sourcePath:
            'modules/catalog/infrastructure/supabase/sql/functions/gone.sql',
        hash: 'sha256:gone',
        signatures: ['catalog.gone()'],
        lastMigration: '20990101001_old.sql',
      ),
    });

    final diff =
        SchemaLockSyncChecker().check(repoRoot: tempDir, lock: lock);

    expect(diff.added, ['catalog.new_fn']);
    expect(diff.changed, ['catalog.search_products']);
    expect(diff.removed, ['catalog.gone']);
    expect(diff.isSynced, isFalse);
  });

  test('empty when sources match lock', () {
    const path =
        'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql';
    const sql =
        'create or replace function catalog.search_products()\n'
        'returns int language sql as \$\$ select 1 \$\$;\n';
    writeSource(path, sql);

    final lock = SchemaLock({
      'catalog.search_products': SchemaLockEntry(
        sourcePath: path,
        hash: sha(sql),
        signatures: const ['catalog.search_products()'],
        lastMigration: '20990101001_old.sql',
      ),
    });

    final diff =
        SchemaLockSyncChecker().check(repoRoot: tempDir, lock: lock);
    expect(diff.isSynced, isTrue);
  });

  test('isPromoteOrReleaseBranch detects release channels', () {
    expect(isPromoteOrReleaseBranch('feature/foo'), isFalse);
    expect(isPromoteOrReleaseBranch('dev'), isFalse);
    expect(isPromoteOrReleaseBranch('main'), isTrue);
    expect(isPromoteOrReleaseBranch('release/1.2'), isTrue);
    expect(isPromoteOrReleaseBranch('promote/catalog'), isTrue);
  });

  test('detectCurrentBranch prefers CI env', () {
    expect(
      detectCurrentBranch(
        environment: const {'CI_COMMIT_REF_NAME': 'feature/x'},
        gitBranch: () => 'main',
      ),
      'feature/x',
    );
  });
}
