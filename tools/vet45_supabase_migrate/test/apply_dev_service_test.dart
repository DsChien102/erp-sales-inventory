import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_supabase_migrate/apply_dev_service.dart';

class FakeSqlExecutor implements SqlExecutor {
  final statements = <String>[];
  final Map<String, String> log = {};

  @override
  Future<void> execute(String sql) async {
    statements.add(sql);
    final insert = RegExp(
      r"insert into vet45_dev\.schema_apply_log.*?values \('([^']+)', '([^']+)'",
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql);
    if (insert != null) {
      log[insert.group(1)!] = insert.group(2)!;
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(String sql) async {
    statements.add(sql);
    if (sql.toLowerCase().contains('schema_apply_log')) {
      return [
        for (final entry in log.entries)
          {'object_name': entry.key, 'hash': entry.value},
      ];
    }
    return const [];
  }
}

void main() {
  late Directory tempDir;
  late FakeSqlExecutor executor;
  late ApplyDevService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vet45_apply_dev_');
    executor = FakeSqlExecutor();
    service = ApplyDevService(executor: executor);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeFunction(String name, String body) {
    final path =
        'modules/catalog/infrastructure/supabase/sql/functions/$name.sql';
    File('${tempDir.path}/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        'create or replace function catalog.$name()\n'
        'returns int language sql as \$\$ select $body \$\$;\n',
      );
  }

  const target = ApplyDevTarget(
    profileId: 'acme',
    environmentId: 'development',
    projectRef: 'abcdefghijklmnop',
  );

  test('refuses staging and production', () {
    expect(
      () => service.assertEnvironmentAllowed('staging'),
      throwsA(isA<ApplyDevException>()),
    );
    expect(
      () => service.assertEnvironmentAllowed('production'),
      throwsA(isA<ApplyDevException>()),
    );
    expect(
      () => service.assertEnvironmentAllowed('development'),
      returnsNormally,
    );
  });

  test('requires confirmation before applying', () async {
    writeFunction('search_products', '1');

    await expectLater(
      service.apply(
        ApplyDevOptions(
          repoRoot: tempDir,
          target: target,
          confirmed: false,
        ),
      ),
      throwsA(isA<ApplyDevConfirmationRequired>()),
    );
    expect(
      executor.statements.any((sql) => sql.contains('create or replace function')),
      isFalse,
    );
  });

  test('applies only objects whose hash differs from apply log', () async {
    writeFunction('search_products', '1');
    writeFunction('create_product', '1');

    final first = await service.apply(
      ApplyDevOptions(
        repoRoot: tempDir,
        target: target,
        confirmed: true,
      ),
    );
    expect(first.applied, containsAll(['catalog.search_products', 'catalog.create_product']));
    expect(first.skipped, isEmpty);

    final createStatements = executor.statements
        .where((sql) => sql.contains('create or replace function'))
        .length;

    writeFunction('search_products', '2');
    final second = await service.apply(
      ApplyDevOptions(
        repoRoot: tempDir,
        target: target,
        confirmed: true,
      ),
    );

    expect(second.applied, ['catalog.search_products']);
    expect(second.skipped, ['catalog.create_product']);
    expect(
      executor.statements
          .where((sql) => sql.contains('create or replace function'))
          .length,
      createStatements + 1,
    );
  });

  test('does not read or apply draft pre/post files', () async {
    writeFunction('search_products', '1');
    File('${tempDir.path}/supabase/migrations/_drafts/demo.pre.sql')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('create table catalog.should_not_run (id int);');
    File('${tempDir.path}/supabase/migrations/_drafts/demo.post.sql')
        .writeAsStringSync('insert into catalog.should_not_run values (1);');

    await service.apply(
      ApplyDevOptions(
        repoRoot: tempDir,
        target: target,
        confirmed: true,
      ),
    );

    expect(
      executor.statements.any((sql) => sql.contains('should_not_run')),
      isFalse,
    );
  });
}
