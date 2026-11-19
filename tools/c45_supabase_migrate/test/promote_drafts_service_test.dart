import 'dart:io';

import 'package:test/test.dart';
import 'package:c45_supabase_migrate/promote_drafts_service.dart';

void main() {
  late Directory tempDir;
  late PromoteDraftsService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('c45_promote_drafts_');
    service = PromoteDraftsService();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Directory _draftsDir() => Directory('${tempDir.path}/supabase/migrations/_drafts');

  Directory _migrationsDir() => Directory('${tempDir.path}/supabase/migrations');

  void writeDraft(String name, String sql) {
    final drafts = _draftsDir()..createSync(recursive: true);
    File('${drafts.path}/$name').writeAsStringSync(sql);
  }

  void writeMigration(String name) {
    final migrations = _migrationsDir()..createSync(recursive: true);
    File('${migrations.path}/$name').writeAsStringSync('-- existing');
  }

  test('lists drafts in numeric prefix order', () {
    writeDraft('10_z.sql', '-- z');
    writeDraft('02_a.sql', '-- a');
    writeDraft('01_b.sql', '-- b');

    final drafts = service.listDraftSqlFiles(_draftsDir());
    expect(drafts.map((file) => file.uri.pathSegments.last).toList(), [
      '01_b.sql',
      '02_a.sql',
      '10_z.sql',
    ]);
  });

  test('builds migration slug without numeric prefix', () {
    expect(service.migrationSlug('01_catalog_guided_create.sql'), 'catalog_guided_create');
    expect(service.migrationSlug('partner_search_read.sql'), 'partner_search_read');
  });

  test('allocates timestamps from current date prefix', () {
    final now = DateTime(2026, 7, 9, 12, 30);

    final timestamps = service.allocateTimestamps(
      count: 2,
      migrationsDirectory: _migrationsDir(),
      referenceTime: now,
    );

    expect(timestamps, ['20260709001', '20260709002']);
  });

  test('continues sequence for migrations on the same date', () {
    writeMigration('20260709003_partner_delete_partner.sql');
    final now = DateTime(2026, 7, 9);

    final timestamps = service.allocateTimestamps(
      count: 2,
      migrationsDirectory: _migrationsDir(),
      referenceTime: now,
    );

    expect(timestamps, ['20260709004', '20260709005']);
  });

  test('ignores legacy 14-digit migrations when allocating today', () {
    writeMigration('20260701000009_partner_delete_partner.sql');
    writeMigration('20260709000001_legacy_same_day.sql');
    final now = DateTime(2026, 7, 9);

    final timestamps = service.allocateTimestamps(
      count: 1,
      migrationsDirectory: _migrationsDir(),
      referenceTime: now,
    );

    expect(timestamps, ['20260709001']);
  });

  test('plans one output file per draft', () {
    writeDraft('01_catalog_a.sql', '-- a');
    writeDraft('02_catalog_b.sql', '-- b');

    final planned = service.plan(
      PromoteDraftsOptions(
        repoRoot: tempDir,
        startTimestamp: '20990101001',
        dryRun: true,
      ),
    );

    expect(planned, hasLength(2));
    expect(planned[0].outputFileName, '20990101001_catalog_a.sql');
    expect(planned[1].outputFileName, '20990101002_catalog_b.sql');
    expect(planned[0].sql, contains('Promoted from _drafts/01_catalog_a.sql'));
  });

  test('bundle-intent merges patch drafts into one migration', () {
    writeDraft(
      '001_catalog_patch_sku_barcode_schema.sql',
      '''
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Touches: _normalize_product_sku

-- schema ddl
select 1;
''',
    );
    writeDraft(
      '002_catalog_patch_sku_barcode_rpcs.sql',
      '''
-- Kind: patch
-- Intent: catalog_sku_barcode_inline_normalize
-- Touches: create_product

-- rpc body
select 2;
''',
    );

    final planned = service.plan(
      PromoteDraftsOptions(
        repoRoot: tempDir,
        startTimestamp: '20990101001',
        dryRun: true,
        bundleIntent: true,
      ),
    );

    expect(planned, hasLength(1));
    expect(
      planned[0].outputFileName,
      '20990101001_catalog_patch_sku_barcode.sql',
    );
    expect(planned[0].sourceDraftNames, hasLength(2));
    expect(planned[0].sql, contains('-- Kind: patch'));
    expect(planned[0].sql, contains('_normalize_product_sku'));
    expect(planned[0].sql, contains('create_product'));
    expect(planned[0].sql, contains('select 1'));
    expect(planned[0].sql, contains('select 2'));
  });

  test('write refuses to overwrite without force', () {
    writeDraft('01_catalog_a.sql', '-- a');
    writeMigration('20990101001_catalog_a.sql');

    expect(
      () => service.promote(
        PromoteDraftsOptions(
          repoRoot: tempDir,
          startTimestamp: '20990101001',
        ),
      ),
      throwsStateError,
    );
  });
}
