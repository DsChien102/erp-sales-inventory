import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInventoryRpc extends Mock implements InventoryRpc {}

void main() {
  group('SupplierProgramRepository', () {
    late MockInventoryRpc mockRpc;
    late SupplierProgramRepository repository;

    setUp(() {
      mockRpc = MockInventoryRpc();
      repository = SupplierProgramRepository(rpc: mockRpc);
    });

    test('list_parses_rows', () async {
      when(() => mockRpc.query('list_supplier_programs')).thenAnswer(
        (_) async => {
          'programs': [
            {
              'program_id': 'prog-1',
              'name': 'Nobivac bậc SL',
              'kind': 'TIER_DISCOUNT',
              'status': 'ACTIVE',
              'supplier_id': 'sup-1',
              'supplier_name': 'Cty Thú Y Á Châu',
              'started_on': '2026-11-10',
              'product_ids': ['prod-1', 'prod-2'],
              'product_count': 2,
              'common_uom': null,
              'tiers': [
                {'min_qty': 100, 'discount_percent': 3},
                {'min_qty': 300, 'discount_percent': 5.5},
              ],
              'buy_qty': null,
              'free_qty': null,
              'target_qty': null,
              'rebate_percent': null,
              'progress_qty': 0,
            },
            {
              'program_id': 'prog-3',
              'name': 'Mốc 1.000 hộp Q4',
              'kind': 'VOLUME_REBATE',
              'status': 'REACHED',
              'supplier_id': 'sup-2',
              'supplier_name': 'NCC A',
              'started_on': '2026-10-01',
              'product_ids': ['prod-1'],
              'product_count': 1,
              'common_uom': 'hộp',
              'tiers': <Map<String, dynamic>>[],
              'buy_qty': null,
              'free_qty': null,
              'target_qty': 1000,
              'rebate_percent': 5,
              'progress_qty': 1000,
            },
          ],
        },
      );

      final rows = await repository.list();

      expect(rows.length, 2);

      final r1 = rows[0];
      expect(r1.id, 'prog-1');
      expect(r1.name, 'Nobivac bậc SL');
      expect(r1.kind, ProgramKind.tierDiscount);
      expect(r1.status, ProgramStatus.active);
      expect(r1.supplierId, 'sup-1');
      expect(r1.supplierName, 'Cty Thú Y Á Châu');
      expect(r1.startedOn, DateTime(2026, 11, 10));
      expect(r1.productIds, ['prod-1', 'prod-2']);
      expect(r1.productCount, 2);
      expect(r1.commonUom, isNull);
      expect(r1.tiers.length, 2);
      expect(r1.tiers[0].minQty, 100);
      expect(r1.tiers[0].discountPercent, 3);
      expect(r1.tiers[1].minQty, 300);
      expect(r1.tiers[1].discountPercent, 5.5);

      final r2 = rows[1];
      expect(r2.id, 'prog-3');
      expect(r2.kind, ProgramKind.volumeRebate);
      expect(r2.status, ProgramStatus.reached);
      expect(r2.commonUom, 'hộp');
      expect(r2.targetQty, 1000);
      expect(r2.rebatePercent, 5);
      expect(r2.progressQty, 1000);
    });

    test('get_parses_detail_receipts_empty', () async {
      when(
        () => mockRpc.query(
          'get_supplier_program',
          {'p_program_id': 'prog-3'},
        ),
      ).thenAnswer(
        (_) async => {
          'program': {
            'program_id': 'prog-3',
            'name': 'Mốc 1.000 hộp Q4',
            'kind': 'VOLUME_REBATE',
            'status': 'ACTIVE',
            'supplier_id': 'sup-2',
            'supplier_name': 'NCC A',
            'started_on': '2026-11-10',
            'product_ids': ['prod-1'],
            'product_count': 1,
            'common_uom': 'hộp',
            'tiers': <Map<String, dynamic>>[],
            'buy_qty': null,
            'free_qty': null,
            'target_qty': 1000,
            'rebate_percent': 5,
            'progress_qty': 400,
            'note': 'Ghi chú Q4',
            'revision': 2,
            'is_locked': false,
            'reached_at': null,
            'ended_at': null,
          },
          'products': [
            {
              'product_id': 'prod-1',
              'name': 'Nobivac DHPPi',
              'code': 'NOBI-01',
              'base_uom': 'hộp',
            },
          ],
          'receipts': <Map<String, dynamic>>[],
          'base_amount_vnd': 0,
        },
      );

      final detail = await repository.get('prog-3');

      expect(detail.row.id, 'prog-3');
      expect(detail.row.progressQty, 400);
      expect(detail.note, 'Ghi chú Q4');
      expect(detail.revision, 2);
      expect(detail.isLocked, isFalse);
      expect(detail.reachedAt, isNull);
      expect(detail.endedAt, isNull);
      expect(detail.products.length, 1);
      expect(detail.products.first.name, 'Nobivac DHPPi');
      expect(detail.products.first.code, 'NOBI-01');
      expect(detail.products.first.baseUom, 'hộp');
      expect(detail.receipts, isEmpty);
      expect(detail.baseAmountVnd, 0);
    });

    test('form_options_parses_active_program', () async {
      when(() => mockRpc.query('get_supplier_program_form_options')).thenAnswer(
        (_) async => {
          'suppliers': [
            {
              'partner_id': 'sup-1',
              'display_name': 'Cty Thú Y Á Châu',
              'active_program': {
                'program_id': 'prog-1',
                'name': 'Nobivac bậc SL',
              },
            },
            {
              'partner_id': 'sup-2',
              'display_name': 'NCC B',
              'active_program': null,
            },
          ],
          'products': [
            {
              'product_id': 'prod-1',
              'name': 'Nobivac DHPPi',
              'code': 'NOBI-01',
              'base_unit_id': 'u-1',
              'base_uom': 'hộp',
            },
          ],
        },
      );

      final opts = await repository.formOptions();

      expect(opts.suppliers.length, 2);
      expect(opts.suppliers[0].partnerId, 'sup-1');
      expect(opts.suppliers[0].displayName, 'Cty Thú Y Á Châu');
      expect(opts.suppliers[0].activeProgram?.id, 'prog-1');
      expect(opts.suppliers[0].activeProgram?.name, 'Nobivac bậc SL');
      expect(opts.suppliers[1].activeProgram, isNull);

      expect(opts.products.length, 1);
      expect(opts.products[0].productId, 'prod-1');
      expect(opts.products[0].baseUnitId, 'u-1');
      expect(opts.products[0].baseUom, 'hộp');
    });

    test('create_sends_scope_and_payload', () async {
      final payload = ProgramPayload(
        supplierId: 'sup-1',
        kind: ProgramKind.tierDiscount,
        name: 'Nobivac bậc SL',
        startedOn: DateTime(2026, 11, 10),
        note: 'Ghi chú',
        productIds: const ['prod-1'],
        tiers: const [
          ProgramTier(minQty: 100, discountPercent: 3),
        ],
      );

      when(
        () => mockRpc.mutate(
          scope: 'supplier_program.create',
          fn: 'create_supplier_program',
          idempotencyKey: 'idem-1',
          params: {
            'p_payload': payload.toJson(),
          },
        ),
      ).thenAnswer((_) async => {'program_id': 'prog-new', 'revision': 1});

      final res = await repository.create(
        idempotencyKey: 'idem-1',
        payload: payload,
      );

      expect(res.id, 'prog-new');
      expect(res.revision, 1);
      verify(
        () => mockRpc.mutate(
          scope: 'supplier_program.create',
          fn: 'create_supplier_program',
          idempotencyKey: 'idem-1',
          params: {
            'p_payload': {
              'supplier_id': 'sup-1',
              'kind': 'TIER_DISCOUNT',
              'name': 'Nobivac bậc SL',
              'started_on': '2026-11-10',
              'note': 'Ghi chú',
              'product_ids': ['prod-1'],
              'tiers': [
                {'min_qty': 100, 'discount_percent': 3},
              ],
            },
          },
        ),
      ).called(1);
    });

    test('hints_preserve_order_and_null', () async {
      when(
        () => mockRpc.query(
          'get_receipt_program_hints',
          {
            'p_supplier_id': 'sup-1',
            'p_lines': [
              {'product_id': 'prod-1', 'paid_qty': 280, 'unit_price': 100000},
              {'product_id': 'prod-2', 'paid_qty': 10, 'unit_price': 50000},
            ],
          },
        ),
      ).thenAnswer(
        (_) async => {
          'lines': [
            {
              'product_id': 'prod-1',
              'hint': {
                'program_id': 'prog-1',
                'program_name': 'Nobivac bậc SL',
                'kind': 'TIER_DISCOUNT',
                'tier': {
                  'min_qty': 100,
                  'discount_percent': 3,
                  'discount_vnd': 840000,
                },
                'next_tier': {
                  'min_qty': 300,
                  'discount_percent': 5,
                  'missing_qty': 20,
                },
                'suggested_free_qty': null,
                'rebate': null,
              },
            },
            {
              'product_id': 'prod-2',
              'hint': null,
            },
          ],
        },
      );

      final hints = await repository.receiptHints(
        supplierId: 'sup-1',
        lines: const [
          (productId: 'prod-1', paidQty: 280, unitPrice: 100000),
          (productId: 'prod-2', paidQty: 10, unitPrice: 50000),
        ],
      );

      expect(hints.length, 2);
      expect(hints[0], isNotNull);
      expect(hints[0]!.programId, 'prog-1');
      expect(hints[0]!.kind, ProgramKind.tierDiscount);
      expect(hints[0]!.tier?.minQty, 100);
      expect(hints[0]!.tier?.percent, 3);
      expect(hints[0]!.tier?.discountVnd, 840000);
      expect(hints[0]!.nextTier?.minQty, 300);
      expect(hints[0]!.nextTier?.percent, 5);
      expect(hints[0]!.nextTier?.missingQty, 20);
      expect(hints[1], isNull);
    });
  });
}

