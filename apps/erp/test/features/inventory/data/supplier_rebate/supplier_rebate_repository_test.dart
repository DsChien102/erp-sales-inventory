import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordedCall {
  final String kind;
  final String fn;
  final String? scope;
  final String? idempotencyKey;
  final Map<String, dynamic> params;

  const _RecordedCall({
    required this.kind,
    required this.fn,
    this.scope,
    this.idempotencyKey,
    required this.params,
  });
}

class _FakeInventoryRpc implements InventoryRpc {
  final List<_RecordedCall> calls = [];
  Map<String, dynamic> nextResponse = {};

  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add(_RecordedCall(kind: 'query', fn: fn, params: params));
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async {
    calls.add(
      _RecordedCall(
        kind: 'mutate',
        fn: fn,
        scope: scope,
        idempotencyKey: idempotencyKey,
        params: params,
      ),
    );
    return nextResponse;
  }
}

void main() {
  group('SupplierRebate models & repository', () {
    late _FakeInventoryRpc fakeRpc;
    late SupplierRebateRepository repository;

    setUp(() {
      fakeRpc = _FakeInventoryRpc();
      repository = SupplierRebateRepository(rpc: fakeRpc);
    });

    test('preview_from_json parses owner and staff masked payloads', () {
      final ownerPreview = RebatePreview.fromJson({
        'program_id': 'prog-14',
        'program_name': 'Mốc 1.000 hộp Q4',
        'supplier_name': 'NCC A',
        'target_qty': 1000,
        'progress_qty': 1000,
        'rebate_percent': 5,
        'uom': 'hộp',
        'base_amount_vnd': 100000000,
        'proposed_amount_vnd': 5000000,
        'amount_vnd': 5000000,
        'inventory_part_total': 1500000,
        'cogs_part_total': 3500000,
        'allocations': [
          {
            'product_id': 'prod-1',
            'name': 'Nobivac DHPPi',
            'uom': 'hộp',
            'paid_qty': 1000,
            'purchase_amount_vnd': 100000000,
            'rebate_part_vnd': 5000000,
            'on_hand_qty': 300,
            'inventory_part_vnd': 1500000,
            'cogs_part_vnd': 3500000,
            'avg_cost_before': 100000,
            'avg_cost_after': 95000,
          },
        ],
      });

      expect(ownerPreview.baseAmountVnd, 100000000);
      expect(ownerPreview.allocations.single.inventoryPartVnd, 1500000);
      expect(ownerPreview.allocations.single.avgCostAfter, 95000);

      // Staff masked JSON on allocations + RecordedRebate
      final maskedRebate = RecordedRebate.fromJson({
        'rebate_id': 'reb-1',
        'document_no': 'CK-2026-11',
        'document_date': '2026-11-12',
        'base_amount_vnd': null,
        'proposed_amount_vnd': null,
        'rebate_amount_vnd': null,
        'override_reason': null,
        'inventory_part_vnd': null,
        'cogs_part_vnd': null,
        'recorded_at': '2026-11-12T07:05:00Z',
        'recorded_by_name': 'Chủ',
        'allocations': [
          {
            'product_id': 'prod-1',
            'name': 'Nobivac DHPPi',
            'uom': 'hộp',
            'paid_qty': 1000,
            'on_hand_qty': 300,
            'rebate_part_vnd': null,
            'inventory_part_vnd': null,
            'cogs_part_vnd': null,
            'avg_cost_before': null,
            'avg_cost_after': null,
          },
        ],
      });

      expect(maskedRebate.rebateAmountVnd, isNull);
      expect(maskedRebate.inventoryPartVnd, isNull);
      expect(maskedRebate.allocations.single.avgCostAfter, isNull);
      expect(maskedRebate.allocations.single.rebatePartVnd, isNull);

      final maskedProjected = ProjectedCost.fromJson({
        'product_id': 'prod-1',
        'uom': 'hộp',
        'progress_qty': 400,
        'target_qty': 1000,
        'missing_qty': 0,
        'reaches_target': true,
        'rebate_estimate': null,
        'avg_now': null,
        'avg_projected': null,
        'default_unit_price': null,
        'financial_masked': true,
      });
      expect(maskedProjected.financialMasked, isTrue);
      expect(maskedProjected.reachesTarget, isTrue);
      expect(maskedProjected.rebateEstimate, isNull);
      expect(maskedProjected.avgProjected, isNull);

      final maskedCompare = SupplierCompare.fromJson({
        'product': {
          'product_id': 'prod-1',
          'name': 'Nobivac DHPPi',
          'code': 'NOBI-01',
          'uom': 'hộp',
        },
        'financial_masked': true,
        'suppliers': [
          {
            'partner_id': 'sup-1',
            'name': 'NCC A',
            'is_system': false,
            'last_landed_unit_cost': null,
            'last_received_on': '2026-11-12',
            'avg_landed_unit_cost': null,
            'receipt_count': 2,
            'paid_qty': 1000,
            'free_qty': 0,
            'program': {
              'program_id': 'prog-1',
              'name': 'CT A',
              'kind': 'VOLUME_REBATE',
              'status': 'ACTIVE',
              'started_on': '2026-11-01',
              'tiers': <Map<String, dynamic>>[],
              'target_qty': 1000,
              'rebate_percent': 5,
              'progress_qty': 400,
              'common_uom': 'hộp',
            },
            'other_program': null,
          },
        ],
      });
      expect(maskedCompare.financialMasked, isTrue);
      expect(maskedCompare.suppliers.single.avgLandedUnitCost, isNull);
      expect(maskedCompare.suppliers.single.program?.supplierId, 'sup-1');
      expect(maskedCompare.suppliers.single.program?.supplierName, 'NCC A');
    });

    test('program_detail_rebate_json', () {
      Map<String, dynamic> baseDetail({
        bool? viewerIsOwner,
        Map<String, dynamic>? rebate,
      }) {
        return {
          'program': {
            'program_id': 'prog-14',
            'name': 'Mốc 1.000 hộp Q4',
            'kind': 'VOLUME_REBATE',
            'status': 'RECORDED',
            'supplier_id': 'sup-a',
            'supplier_name': 'NCC A',
            'started_on': '2026-11-01',
            'product_ids': ['prod-1'],
            'product_count': 1,
            'common_uom': 'hộp',
            'tiers': <Map<String, dynamic>>[],
            'target_qty': 1000,
            'rebate_percent': 5,
            'progress_qty': 1000,
          },
          'products': <Map<String, dynamic>>[],
          'receipts': <Map<String, dynamic>>[],
          'base_amount_vnd': 100000000,
          'viewer_is_owner': ?viewerIsOwner,
          'rebate': ?rebate,
        };
      }

      final withRebate = ProgramDetail.fromJson(
        baseDetail(
          viewerIsOwner: true,
          rebate: {
            'rebate_id': 'reb-14',
            'document_no': 'CK-2026-14',
            'document_date': '2026-11-12',
            'base_amount_vnd': 100000000,
            'proposed_amount_vnd': 5000000,
            'rebate_amount_vnd': 5000000,
            'override_reason': null,
            'inventory_part_vnd': 1500000,
            'cogs_part_vnd': 3500000,
            'recorded_at': '2026-11-12T07:05:00Z',
            'recorded_by_name': 'Chủ',
            'allocations': <Map<String, dynamic>>[],
          },
        ),
      );
      expect(withRebate.viewerIsOwner, isTrue);
      expect(withRebate.rebate?.documentNo, 'CK-2026-14');
      expect(withRebate.rebate?.inventoryPartVnd, 1500000);

      // Legacy G5-2b JSON without viewer_is_owner / rebate
      final legacy = ProgramDetail.fromJson(baseDetail());
      expect(legacy.viewerIsOwner, isFalse);
      expect(legacy.rebate, isNull);
    });

    test('repository_calls_one_rpc', () async {
      fakeRpc.nextResponse = {
        'program_id': 'prog-1',
        'program_name': 'CT 1',
        'supplier_name': 'NCC A',
        'target_qty': 1000,
        'progress_qty': 1000,
        'rebate_percent': 5,
        'uom': 'hộp',
        'base_amount_vnd': 100000000,
        'proposed_amount_vnd': 5000000,
        'amount_vnd': 5000000,
        'allocations': <Map<String, dynamic>>[],
        'inventory_part_total': 1500000,
        'cogs_part_total': 3500000,
      };
      await repository.preview(programId: 'prog-1', amountVnd: 4500000);
      expect(fakeRpc.calls.single.kind, 'query');
      expect(fakeRpc.calls.single.fn, 'preview_supplier_rebate');
      expect(fakeRpc.calls.single.params, {
        'p_program_id': 'prog-1',
        'p_amount_vnd': 4500000,
      });

      fakeRpc.calls.clear();
      fakeRpc.nextResponse = {
        ...fakeRpc.nextResponse,
        'rebate_id': 'reb-1',
      };
      final recorded = await repository.record(
        idempotencyKey: 'key-1',
        programId: 'prog-1',
        documentNo: 'CK-01',
        documentDate: DateTime(2026, 11, 12),
        amountVnd: 5000000,
        overrideReason: null,
      );
      expect(recorded.rebateId, 'reb-1');
      expect(fakeRpc.calls.single.kind, 'mutate');
      expect(fakeRpc.calls.single.scope, 'supplier_rebate.record');
      expect(fakeRpc.calls.single.fn, 'record_supplier_rebate');
      expect(fakeRpc.calls.single.idempotencyKey, 'key-1');
      final recordPayload =
          fakeRpc.calls.single.params['p_payload'] as Map<String, dynamic>;
      expect(fakeRpc.calls.single.params['p_program_id'], 'prog-1');
      expect(recordPayload.containsKey('override_reason'), isFalse);
      expect(recordPayload, {
        'document_no': 'CK-01',
        'document_date': '2026-11-12',
        'amount_vnd': 5000000,
      });

      // With overrideReason
      fakeRpc.calls.clear();
      await repository.record(
        idempotencyKey: 'key-2',
        programId: 'prog-1',
        documentNo: 'CK-02',
        documentDate: DateTime(2026, 11, 12),
        amountVnd: 4000000,
        overrideReason: 'Thương lượng lại',
      );
      final recordPayload2 =
          fakeRpc.calls.single.params['p_payload'] as Map<String, dynamic>;
      expect(recordPayload2['override_reason'], 'Thương lượng lại');

      // projectedCost
      fakeRpc.calls.clear();
      fakeRpc.nextResponse = {
        'product_id': 'prod-1',
        'uom': 'hộp',
        'progress_qty': 400,
        'target_qty': 1000,
        'missing_qty': 0,
        'reaches_target': true,
        'rebate_estimate': 5000000,
        'avg_now': 100000,
        'avg_projected': 95000,
        'default_unit_price': 100000,
        'financial_masked': false,
      };
      await repository.projectedCost(
        programId: 'prog-1',
        productId: 'prod-1',
        extraQty: 600,
        unitPrice: 100000,
      );
      expect(fakeRpc.calls.single.kind, 'query');
      expect(fakeRpc.calls.single.fn, 'get_projected_cost');
      expect(fakeRpc.calls.single.params, {
        'p_program_id': 'prog-1',
        'p_product_id': 'prod-1',
        'p_extra_qty': 600,
        'p_unit_price': 100000,
      });

      // compareSuppliers
      fakeRpc.calls.clear();
      fakeRpc.nextResponse = {
        'product': {
          'product_id': 'prod-1',
          'name': 'Nobivac DHPPi',
          'code': 'NOBI-01',
          'uom': 'hộp',
        },
        'financial_masked': false,
        'suppliers': <Map<String, dynamic>>[],
      };
      await repository.compareSuppliers('prod-1');
      expect(fakeRpc.calls.single.kind, 'query');
      expect(fakeRpc.calls.single.fn, 'compare_suppliers');
      expect(fakeRpc.calls.single.params, {'p_product_id': 'prod-1'});
    });

    test('error_messages', () {
      String msg(String code) => inventoryErrorMessage(
            AppException(code, serverMessage: 'raw'),
            fallback: 'fallback',
          );

      expect(
        msg(InventoryErrorCode.programNotReached),
        'Chương trình chưa đạt mốc hoặc đã ghi nhận chiết khấu.',
      );
      expect(
        msg(InventoryErrorCode.rebateAmountInvalid),
        'Số tiền ghi nhận phải từ 1 đ đến tổng tiền mua.',
      );
      expect(
        msg(InventoryErrorCode.rebateReasonRequired),
        'Nhập lý do khi số tiền khác đề xuất.',
      );
    });
  });
}
