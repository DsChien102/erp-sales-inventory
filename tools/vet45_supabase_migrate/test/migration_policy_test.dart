import 'package:test/test.dart';
import 'package:vet45_supabase_migrate/migration_header.dart';
import 'package:vet45_supabase_migrate/migration_policy.dart';
import 'package:vet45_supabase_migrate/migration_registry.dart';
import 'package:vet45_supabase_migrate/promote_drafts_service.dart';
import 'package:vet45_supabase_migrate/sql_function_extractor.dart';

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
