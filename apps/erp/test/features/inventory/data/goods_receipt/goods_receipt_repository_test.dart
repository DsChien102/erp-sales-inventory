import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';

class _MockInventoryRpc extends Fake implements InventoryRpc {
  String? lastFunction;
  Map<String, dynamic>? lastParams;
  String? lastIdempotencyKey;
  Map<String, dynamic> nextResponse = {};

  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async {
    lastFunction = fn;
    lastParams = params;
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> mutate({
    required String scope,
    required String idempotencyKey,
    required String fn,
    required Map<String, dynamic> params,
  }) async {
    lastFunction = fn;
    lastIdempotencyKey = idempotencyKey;
    lastParams = params;
    return nextResponse;
  }
}

void main() {
  late _MockInventoryRpc rpc;
  late GoodsReceiptRepository repository;

  setUp(() {
    rpc = _MockInventoryRpc();
    repository = GoodsReceiptRepository(rpc: rpc);
  });

  group('GoodsReceiptRepository', () {
    test('form_options_parse', () async {
      rpc.nextResponse = {
        'warehouse_name': 'Kho trung tâm',
        'today': '2026-11-10',
        'suppliers': [
          {'partner_id': 's1', 'display_name': 'Á Châu', 'code': 'AC', 'is_system': false},
        ],
        'products': [
          {
            'product_id': 'p1',
            'name': 'Nobivac',
            'code': 'NOB',
            'barcode': '893',
            'base_uom': 'hộp',
            'tracking_mode': 'lot',
            'expiry_required': true,
            'units': [
              {'unit_id': 'u1', 'name': 'hộp', 'rate': 1, 'is_base': true},
            ],
          },
        ],
        'lots': [
          {
            'product_id': 'p1',
            'lot_code': 'DH1',
            'expiry_date': '2026-11-30',
            'expiry_precision': 'DAY',
          },
        ],
      };

      final options = await repository.formOptions();
      expect(options.warehouseName, 'Kho trung tâm');
      expect(options.suppliers.length, 1);
      expect(options.suppliers.first.name, 'Á Châu');
      expect(options.products.length, 1);
      expect(options.products.first.isLotTracked, isTrue);
      expect(options.lots.length, 1);
      expect(options.lots.first.code, 'DH1');
      expect(options.lots.first.expiry?.day, 30);
    });

    test('record_passes_scope_and_key', () async {
      rpc.nextResponse = {
        'receipt_id': 'rc-1',
        'receipt_no': 'PN-261110-01',
        'supplier_name': 'Á Châu',
        'supplier_doc_no': 'HĐ 01',
        'business_date': '2026-11-10',
        'line_count': 1,
        'lot_count': 1,
        'landed_total_vnd': 1000000,
        'created_by_name': 'Chủ kho',
        'stock_changes': [
          {'product_name': 'Nobivac', 'base_uom': 'hộp', 'before': 0, 'after': 10},
        ],
        'reached_programs': [
          {'program_id': 'pr-1', 'name': 'Tích lũy'},
        ],
      };

      final result = await repository.record(
        idempotencyKey: 'idem-key-1',
        payload: {'supplier_id': 's1'},
      );

      expect(rpc.lastFunction, 'record_goods_receipt');
      expect(rpc.lastIdempotencyKey, 'idem-key-1');
      expect(result.receiptNo, 'PN-261110-01');
      expect(result.stockChanges.length, 1);
      expect(result.reachedPrograms.length, 1);
    });

    test('get_parse_lots', () async {
      rpc.nextResponse = {
        'receipt': {
          'receipt_id': 'rc-1',
          'receipt_no': 'PN-261110-01',
          'supplier_id': 's1',
          'supplier_name': 'Á Châu',
          'supplier_is_system': false,
          'supplier_doc_no': 'HĐ 01',
          'business_date': '2026-11-10',
          'warehouse_name': 'Kho trung tâm',
          'freight_cost_vnd': 0,
          'trade_discount_vnd': 0,
          'purchase_total_vnd': 1000000,
          'landed_total_vnd': 1000000,
          'line_count': 1,
          'lot_count': 1,
          'created_by_name': 'Chủ kho',
          'created_at': '2026-11-10T10:00:00Z',
        },
        'lines': [
          {
            'line_id': 'l-1',
            'line_no': 1,
            'product_id': 'p1',
            'product_name': 'Nobivac',
            'product_code': 'NOB',
            'base_uom': 'hộp',
            'unit_name': 'hộp',
            'conversion_rate': 1,
            'paid_qty': 10,
            'free_qty': 0,
            'unit_price_vnd': 100000,
            'gross_amount_vnd': 1000000,
            'program_id': null,
            'program_name': null,
            'program_kind': null,
            'tier_discount_percent': null,
            'tier_discount_vnd': 0,
            'purchase_amount_vnd': 1000000,
            'allocated_freight_vnd': 0,
            'allocated_discount_vnd': 0,
            'landed_amount_vnd': 1000000,
            'landed_unit_cost': 100000.0,
            'lots': [
              {
                'lot_code': 'DH1',
                'expiry_date': '2026-11-30',
                'expiry_precision': 'DAY',
                'manufacture_date': '2026-05-01',
                'quantity': 10,
                'allocated_landed_cost_vnd': 1000000,
              },
            ],
          },
        ],
      };

      final detail = await repository.get('rc-1');
      expect(detail.header.receiptNo, 'PN-261110-01');
      expect(detail.lines.first.lots.length, 1);
      final lot = detail.lines.first.lots.first;
      expect(lot.lotCode, 'DH1');
      expect(lot.manufactureDate, '2026-05-01');
      expect(lot.allocatedLandedCostVnd, 1000000);
    });

    test('list_sends_limit_100_and_parses_rows', () async {
      rpc.nextResponse = {
        'receipts': [
          {
            'receipt_id': 'rc-1',
            'receipt_no': 'PN-261110-01',
            'supplier_id': 's1',
            'supplier_name': 'Á Châu',
            'business_date': '2026-11-10',
            'line_count': 1,
            'lot_count': 1,
            'landed_total_vnd': 1000000,
            'created_at': '2026-11-10T10:00:00Z',
          },
        ],
      };

      final rows = await repository.list(supplierId: 's1');
      expect(rpc.lastFunction, 'list_goods_receipts');
      expect(rpc.lastParams?['p_supplier_id'], 's1');
      expect(rpc.lastParams?['p_limit'], 100);
      expect(rows.length, 1);
      expect(rows.first.receiptNo, 'PN-261110-01');
    });
  });
}
