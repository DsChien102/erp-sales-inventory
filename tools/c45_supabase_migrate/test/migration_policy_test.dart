import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:c45_supabase_migrate/migration_header.dart';
import 'package:c45_supabase_migrate/migration_policy.dart';
import 'package:c45_supabase_migrate/migration_registry.dart';
import 'package:c45_supabase_migrate/promote_drafts_service.dart';
import 'package:c45_supabase_migrate/schema_lock.dart';
import 'package:c45_supabase_migrate/sql_function_extractor.dart';

String _sha256(String content) =>
    'sha256:${sha256.convert(utf8.encode(content))}';

void main() {
  group('extractFunctionsFromSql', () {
    test('finds qualified function names', () {
      const sql = r'''
create or replace function catalog.create_product()
returns void language sql as $$ select 1 $$;

CREATE OR REPLACE FUNCTION catalog.search_products()
RETURNS void LANGUAGE sql AS $$ select 1 $$;
''';

      expect(
        extractFunctionsFromSql(sql),
        ['catalog.create_product', 'catalog.search_products'],
      );
    });
  });

  group('MigrationHeader', () {
    test('parses Touches csv', () {
      const sql = '''
-- Title: catalog patch
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Touches: _normalize_product_sku, create_product, search_products
-- Depends on: 20260710001_catalog_product_reference_id

select 1;
''';

      final header = MigrationHeader.parse(sql);
      expect(header.kind, 'patch');
      expect(header.intent, 'catalog_sku_barcode_inline_normalize');
      expect(
        header.touches,
        [
          '_normalize_product_sku',
          'create_product',
          'search_products',
        ],
      );
      expect(header.dependsOn, ['20260710001_catalog_product_reference_id']);
    });
  });

  group('MigrationPolicyVerifier', () {
    final registry = MigrationRegistry(
      schemas: {
        'catalog': {
          'create_product': '20260710001_catalog_product_reference_id.sql',
          'search_products': '20260709015_catalog_custom_field_search.sql',
          'get_product_control_center':
              '20260709018_catalog_product_image_read_fix.sql',
        },
      },
      bootstrapGrandfathered: [
        '20260709001_catalog_guided_create.sql',
      ],
    );

    test('patch with matching Touches passes', () {
      const sql = r'''
-- Kind: patch
-- Intent: test_patch
-- Touches: create_product, search_products

create or replace function catalog.create_product() returns void language sql as $$ select 1 $$;
create or replace function catalog.search_products() returns void language sql as $$ select 1 $$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_catalog_patch_test.sql',
        sql: sql,
        registry: registry,
      );

      expect(
        violations.where((v) => v.severity == PolicySeverity.error),
        isEmpty,
      );
    });

    test('patch with undeclared function fails', () {
      const sql = r'''
-- Kind: patch
-- Intent: test_patch
-- Touches: create_product

create or replace function catalog.create_product() returns void language sql as $$ select 1 $$;
create or replace function catalog.get_product_control_center() returns void language sql as $$ select 1 $$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_catalog_patch_test.sql',
        sql: sql,
        registry: registry,
      );

      expect(
        violations.any((v) => v.code == 'touches_match_body'),
        isTrue,
      );
    });

    test('grandfather file without Kind is skipped', () {
      const sql = r'''
create or replace function catalog.create_product() returns void language sql as $$ select 1 $$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260709001_catalog_guided_create.sql',
        sql: sql,
        registry: registry,
      );

      expect(violations, isEmpty);
    });

    test('generated with Touches not matching body fails', () {
      const sql = r'''
-- Kind: generated
-- Intent: test_generated
-- Touches: catalog.create_product

-- region: functions

create or replace function catalog.search_products() returns void language sql as $$ select 1 $$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_test_generated.sql',
        sql: sql,
        registry: registry,
      );

      expect(
        violations.where((v) => v.code == 'touches_match_body'),
        hasLength(2),
      );
    });

    test('generated without Intent fails', () {
      const sql = r'''
-- Kind: generated
-- Touches: catalog.create_product

create or replace function catalog.create_product() returns void language sql as $$ select 1 $$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_test_generated.sql',
        sql: sql,
        registry: registry,
      );

      expect(violations.map((v) => v.code), ['header_intent']);
    });

    test('patch exceeds function cap fails', () {
      final functions = List.generate(
        9,
        (index) =>
            'create or replace function catalog.fn_$index() returns void language sql as \$\$ select 1 \$\$;',
      );
      final sql = '''
-- Kind: patch
-- Intent: too_many
-- Touches: ${List.generate(9, (i) => 'fn_$i').join(', ')}

${functions.join('\n')}
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_catalog_patch_cap.sql',
        sql: sql,
        registry: registry,
      );

      expect(
        violations.any((v) => v.code == 'patch_function_cap'),
        isTrue,
      );
    });

    test('non-generated migration replacing adopted object fails', () {
      const sql = r'''
-- Kind: patch
-- Intent: bypass_adopted
-- Touches: search_products

create or replace function catalog.search_products() returns void language sql as $$ select 1 $$;
''';

      final lock = SchemaLock({
        'catalog.search_products': const SchemaLockEntry(
          sourcePath:
              'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql',
          hash: 'sha256:abc',
          signatures: ['catalog.search_products()'],
          lastMigration: '20990101001_first.sql',
        ),
      });

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_catalog_patch_bypass.sql',
        sql: sql,
        registry: registry,
        options: MigrationPolicyOptions(schemaLock: lock),
      );

      expect(
        violations.any((v) => v.code == 'adopted_object_bypass'),
        isTrue,
      );
    });

    test('generated migration may redefine adopted object', () {
      const sql = r'''
-- Kind: generated
-- Intent: ok_generated
-- Touches: catalog.search_products

-- region: functions

create or replace function catalog.search_products() returns void language sql as $$ select 1 $$;
''';

      final lock = SchemaLock({
        'catalog.search_products': const SchemaLockEntry(
          sourcePath:
              'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql',
          hash: 'sha256:abc',
          signatures: ['catalog.search_products()'],
          lastMigration: '20260711001_ok_generated.sql',
        ),
      });

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20260711001_ok_generated.sql',
        sql: sql,
        registry: registry,
        options: MigrationPolicyOptions(schemaLock: lock),
      );

      expect(
        violations.where((v) => v.code == 'adopted_object_bypass'),
        isEmpty,
      );
    });

    test('generated region hand-edit fails byte-match', () {
      final temp = Directory.systemTemp.createTempSync('c45_policy_region_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });

      const source = '''
create or replace function catalog.search_products()
returns void language sql as \$\$ select 1 \$\$;
''';
      final sourcePath =
          'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql';
      File('${temp.path}/$sourcePath')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(source);

      final lockHash = _sha256(source);
      final lock = SchemaLock({
        'catalog.search_products': SchemaLockEntry(
          sourcePath: sourcePath,
          hash: lockHash,
          signatures: const ['catalog.search_products()'],
          lastMigration: '20990101001_search.sql',
        ),
      });

      const sql = '''
-- Kind: generated
-- Intent: search
-- Touches: catalog.search_products

-- region: functions

create or replace function catalog.search_products()
returns void language sql as \$\$ select 999 \$\$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20990101001_search.sql',
        sql: sql,
        registry: registry,
        options: MigrationPolicyOptions(
          schemaLock: lock,
          repoRoot: temp,
        ),
      );

      expect(
        violations.any((v) => v.code == 'generated_region_mismatch'),
        isTrue,
      );
    });

    test('generated region matching source passes; pre/post may differ', () {
      final temp = Directory.systemTemp.createTempSync('c45_policy_ok_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });

      const source = '''
create or replace function catalog.search_products()
returns void language sql as \$\$ select 1 \$\$;
''';
      final sourcePath =
          'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql';
      File('${temp.path}/$sourcePath')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(source);

      final lock = SchemaLock({
        'catalog.search_products': SchemaLockEntry(
          sourcePath: sourcePath,
          hash: _sha256(source),
          signatures: const ['catalog.search_products()'],
          lastMigration: '20990101001_search.sql',
        ),
      });

      final sql = '''
-- Kind: generated
-- Intent: search
-- Touches: catalog.search_products

-- region: pre

-- hand-edited DDL ok
create table if not exists catalog.scratch (id int);

-- region: functions

$source
-- region: post

insert into catalog.scratch values (1);
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20990101001_search.sql',
        sql: sql,
        registry: registry,
        options: MigrationPolicyOptions(
          schemaLock: lock,
          repoRoot: temp,
        ),
      );

      expect(
        violations.where((v) => v.severity == PolicySeverity.error),
        isEmpty,
      );
    });

    test('generated region with extra SQL beyond source fails', () {
      final temp = Directory.systemTemp.createTempSync('c45_policy_extra_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });

      const source = '''
create or replace function catalog.search_products()
returns void language sql as \$\$ select 1 \$\$;
''';
      final sourcePath =
          'modules/catalog/infrastructure/supabase/sql/functions/search_products.sql';
      File('${temp.path}/$sourcePath')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(source);

      final lock = SchemaLock({
        'catalog.search_products': SchemaLockEntry(
          sourcePath: sourcePath,
          hash: _sha256(source),
          signatures: const ['catalog.search_products()'],
          lastMigration: '20990101001_search.sql',
        ),
      });

      final sql = '''
-- Kind: generated
-- Intent: search
-- Touches: catalog.search_products

-- region: functions

$source
create or replace function catalog.sneaky() returns void language sql as \$\$ select 1 \$\$;
''';

      final violations = MigrationPolicyVerifier().verifyFile(
        fileName: '20990101001_search.sql',
        sql: sql,
        registry: registry,
        options: MigrationPolicyOptions(
          schemaLock: lock,
          repoRoot: temp,
        ),
      );

      expect(
        violations.any((v) => v.code == 'generated_region_mismatch'),
        isTrue,
      );
    });
  });

  group('PromoteDraftsService bundle-intent', () {
    final service = PromoteDraftsService();

    test('extracts bundle intent key from draft name', () {
      expect(
        service.bundleIntentKey('001_catalog_patch_sku_barcode_schema.sql'),
        'catalog_patch_sku_barcode',
      );
    });

    test('returns null for non-patch draft names', () {
      expect(
        service.bundleIntentKey('catalog_product_sku_barcode_inline_normalize.sql'),
        isNull,
      );
    });
  });
}
