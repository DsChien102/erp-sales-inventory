import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInventoryRpc extends Mock implements InventoryRpc {}

void main() {
  group('StockPolicyRepository', () {
    late MockInventoryRpc mockRpc;
    late StockPolicyRepository repository;

    setUp(() {
      mockRpc = MockInventoryRpc();
      repository = StockPolicyRepository(rpc: mockRpc);
    });

    test('load_parses_snapshot', () async {
      when(() => mockRpc.query('get_stock_policy')).thenAnswer(
        (_) async => {
          'revision': 5,
          'is_owner': true,
          'near_expiry_days': 30,
          'products': [
            {
              'product_id': 'p1',
              'name': 'Nobivac',
              'code': 'NOBI',
              'base_uom': 'hộp',
              'is_lot_tracked': true,
              'available': 10,
              'has_expired': false,
              'has_near_expiry': true,
              'reorder_threshold': null,
              'target_level': null,
              'near_expiry_days': null,
            },
            {
              'product_id': 'p2',
              'name': 'Amox',
              'code': 'AMOX',
              'base_uom': 'vỉ',
              'is_lot_tracked': false,
              'available': 50,
              'has_expired': false,
              'has_near_expiry': false,
              'reorder_threshold': 20,
              'target_level': 40,
              'near_expiry_days': 60,
            },
          ],
        },
      );

      final snapshot = await repository.load();

      expect(snapshot.revision, 5);
      expect(snapshot.isOwner, isTrue);
      expect(snapshot.nearExpiryDays, 30);
      expect(snapshot.products.length, 2);

      final p1 = snapshot.products[0];
      expect(p1.productId, 'p1');
      expect(p1.name, 'Nobivac');
      expect(p1.code, 'NOBI');
      expect(p1.uom, 'hộp');
      expect(p1.isLotTracked, isTrue);
      expect(p1.available, 10);
      expect(p1.hasExpired, isFalse);
      expect(p1.hasNearExpiry, isTrue);
      expect(p1.threshold, isNull);
      expect(p1.target, isNull);
      expect(p1.nearExpiryDaysOverride, isNull);
      expect(p1.configured, isFalse);

      final p2 = snapshot.products[1];
      expect(p2.threshold, 20);
      expect(p2.target, 40);
      expect(p2.nearExpiryDaysOverride, 60);
      expect(p2.configured, isTrue);
    });

    test('save_thresholds_sends_lines', () async {
      when(
        () => mockRpc.mutate(
          scope: 'stock_policy.thresholds',
          fn: 'save_stock_thresholds',
          idempotencyKey: 'key-123',
          params: {
            'p_expected_revision': 5,
            'p_lines': [
              {
                'product_id': 'p1',
                'reorder_threshold': 10,
                'target_level': 30,
              },
            ],
          },
        ),
      ).thenAnswer((_) async => {'revision': 6});

      final rev = await repository.saveThresholds(
        idempotencyKey: 'key-123',
        expectedRevision: 5,
        changes: const [
          ThresholdChange(productId: 'p1', threshold: 10, target: 30),
        ],
      );

      expect(rev, 6);
      verify(
        () => mockRpc.mutate(
          scope: 'stock_policy.thresholds',
          fn: 'save_stock_thresholds',
          idempotencyKey: 'key-123',
          params: {
            'p_expected_revision': 5,
            'p_lines': [
              {
                'product_id': 'p1',
                'reorder_threshold': 10,
                'target_level': 30,
              },
            ],
          },
        ),
      ).called(1);
    });

    test('save_near_expiry_sends_null_default', () async {
      when(
        () => mockRpc.mutate(
          scope: 'stock_policy.near_expiry',
          fn: 'save_near_expiry_policy',
          idempotencyKey: 'key-456',
          params: {
            'p_expected_revision': 3,
            'p_default_days': null,
            'p_overrides': [
              {'product_id': 'p1', 'days': 60},
            ],
          },
        ),
      ).thenAnswer((_) async => {'revision': 4});

      final rev = await repository.saveNearExpiry(
        idempotencyKey: 'key-456',
        expectedRevision: 3,
        defaultDays: null,
        overrides: const [
          NearExpiryOverride(productId: 'p1', days: 60),
        ],
      );

      expect(rev, 4);
    });
  });
}

