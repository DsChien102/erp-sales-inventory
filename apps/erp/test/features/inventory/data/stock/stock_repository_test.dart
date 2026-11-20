import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockInventoryRpc extends Mock implements InventoryRpc {}

void main() {
  late _MockInventoryRpc mockRpc;
  late StockRepository repository;

  setUp(() {
    mockRpc = _MockInventoryRpc();
    repository = StockRepository(rpc: mockRpc);
  });

  group('StockRepository & models', () {
    test('overview_parses', () async {
      when(() => mockRpc.query('list_stock_overview')).thenAnswer(
        (_) async => {
          'as_of': '2026-09-17T14:30:00Z',
          'warehouse_name': 'Kho trung tâm',
          'products': [
            {
              'product_id': 'p-oxy',
              'name': 'Oxytetracycline LA',
              'code': 'SP-000147',
              'barcode': '8938500004099',
              'base_uom': 'chai',
              'is_lot_tracked': false,
              'physical': 11,
              'available': 11,
              'has_expired': false,
              'has_near_expiry': false,
              'reorder_threshold': null,
            },
          ],
        },
      );

      final overview = await repository.loadOverview();
      expect(overview.warehouseName, 'Kho trung tâm');
      expect(overview.asOf.isUtc, isFalse);
      expect(overview.products, hasLength(1));

      final item = overview.products.single;
      expect(item.productId, 'p-oxy');
      expect(item.name, 'Oxytetracycline LA');
      expect(item.code, 'SP-000147');
      expect(item.barcode, '8938500004099');
      expect(item.uom, 'chai');
      expect(item.isLotTracked, isFalse);
      expect(item.physical, 11);
      expect(item.available, 11);
      expect(item.threshold, isNull);
      expect(item.indicators, [StockIndicator.notConfigured]);
    });

    test('detail_parses_lots_and_cost', () async {
      when(
        () => mockRpc.query('get_stock_detail', {'p_product_id': 'p-tylo'}),
      ).thenAnswer(
        (_) async => {
          'as_of': '2026-09-17T14:30:00Z',
          'warehouse_name': 'Kho trung tâm',
          'is_owner': true,
          'financial_masked': false,
          'product': {
            'product_id': 'p-tylo',
            'name': 'Tylosin 20%',
            'code': 'SP-000122',
            'base_uom': 'lọ',
            'is_lot_tracked': true,
          },
          'physical': 14,
          'available': 3,
          'expired_quantity': 11,
          'reorder_threshold': 8,
          'target_level': 24,
          'lots': [
            {
              'lot_id': 'lot-1',
              'lot_code': 'TY2408',
              'expiry_date': '2026-08-31',
              'expiry_precision': 'DAY',
              'physical': 11,
              'is_expired': true,
              'is_near_expiry': false,
              'days_to_expiry': -17,
            },
            {
              'lot_id': 'lot-2',
              'lot_code': 'TY2511',
              'expiry_date': '2026-11-30',
              'expiry_precision': 'DAY',
              'physical': 3,
              'is_expired': false,
              'is_near_expiry': false,
              'days_to_expiry': 74,
            },
          ],
          'latest_movement': {
            'movement_kind': 'RECEIPT',
            'intent_type': 'RECEIPT',
            'intent_id': 'int-1',
            'quantity_delta': 14,
            'business_date': '2026-09-15',
          },
          'cost': {
            'method': 'PERIODIC',
            'official_unit_cost': null,
            'moving_avg_cost': 117940,
            'ledger_value_vnd': 1651160,
          },
        },
      );

      final detail = await repository.loadDetail('p-tylo');
      expect(detail.isOwner, isTrue);
      expect(detail.productId, 'p-tylo');
      expect(detail.name, 'Tylosin 20%');
      expect(detail.code, 'SP-000122');
      expect(detail.uom, 'lọ');
      expect(detail.isLotTracked, isTrue);
      expect(detail.physical, 14);
      expect(detail.available, 3);
      expect(detail.expiredQuantity, 11);
      expect(detail.threshold, 8);
      expect(detail.target, 24);
      expect(detail.lots, hasLength(2));
      expect(detail.lots.first.code, 'TY2408');
      expect(detail.lots.first.expiry, const LotDate(year: 2026, month: 8, day: 31));
      expect(detail.lots.first.isExpired, isTrue);
      expect(detail.cost, isNotNull);
      expect(detail.cost!.method, CostMethod.periodic);
      expect(detail.cost!.officialUnitCost, isNull);
      expect(detail.cost!.movingAvgCost, 117940);
      expect(detail.cost!.ledgerValueVnd, 1651160);
      expect(detail.cost!.provisional, isTrue);
      expect(
        detail.indicators,
        containsAll([StockIndicator.expired, StockIndicator.low]),
      );
    });

    test('lot_date_from_json_month', () {
      final date = lotDateFromJson('2027-11-30', 'MONTH');
      expect(date, isNotNull);
      expect(date!.precision, DatePrecision.month);
      expect(date.format(), '11/2027');

      final yearOnly = lotDateFromJson('2027-12-31', 'YEAR');
      expect(yearOnly, isNotNull);
      expect(yearOnly!.precision, DatePrecision.year);
      expect(yearOnly.format(), '2027');
    });

    test('detail_cost_null_when_masked', () async {
      when(
        () => mockRpc.query('get_stock_detail', {'p_product_id': 'p-tylo'}),
      ).thenAnswer(
        (_) async => {
          'as_of': '2026-09-17T14:30:00Z',
          'warehouse_name': 'Kho trung tâm',
          'is_owner': false,
          'financial_masked': true,
          'product': {
            'product_id': 'p-tylo',
            'name': 'Tylosin 20%',
            'code': 'SP-000122',
            'base_uom': 'lọ',
            'is_lot_tracked': true,
          },
          'physical': 14,
          'available': 3,
          'expired_quantity': 11,
          'reorder_threshold': 8,
          'target_level': 24,
          'lots': const <Map<String, dynamic>>[],
          'latest_movement': null,
          'cost': null,
        },
      );

      final detail = await repository.loadDetail('p-tylo');
      expect(detail.isOwner, isFalse);
      expect(detail.cost, isNull);
    });

    test('latest_movement_label', () {
      StockLatestMovement make(String kind) => StockLatestMovement(
            kind: kind,
            intentType: kind,
            intentId: 'id-1',
            delta: 1,
            businessDate: DateTime(2026, 9, 17),
          );

      expect(make('RECEIPT').label, 'Nhận hàng');
      expect(make('SALE').label, 'Xuất bán');
      expect(make('SALE_REVERSAL').label, 'Huỷ bán');
      expect(make('RETURN_IN').label, 'Khách trả');
      expect(make('COUNT_GAIN').label, 'Kiểm kê');
      expect(make('COUNT_LOSS').label, 'Kiểm kê');
      expect(make('WRITE_OFF').label, 'Điều chỉnh giảm');
    });
  });
}

