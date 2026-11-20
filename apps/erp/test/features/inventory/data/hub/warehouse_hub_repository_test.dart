import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';

class MockInventoryRpc extends Mock implements InventoryRpc {}

void main() {
  group('WarehouseHubRepository', () {
    late MockInventoryRpc mockRpc;
    late WarehouseHubRepository repository;

    setUp(() {
      mockRpc = MockInventoryRpc();
      repository = WarehouseHubRepository(rpc: mockRpc);
    });

    test('getSummary_calls_rpc_and_parses_activated', () async {
      when(() => mockRpc.query('get_warehouse_hub_summary'))
          .thenAnswer((_) async => {'activated': true, 'problems': null});

      final summary = await repository.getSummary();

      expect(summary.activated, isTrue);
      expect(summary.problems, isNull);
      verify(() => mockRpc.query('get_warehouse_hub_summary')).called(1);
    });

    test('getSummary_handles_activated_false', () async {
      when(() => mockRpc.query('get_warehouse_hub_summary'))
          .thenAnswer((_) async => {'activated': false, 'problems': null});

      final summary = await repository.getSummary();

      expect(summary.activated, isFalse);
      expect(summary.problems, isNull);
    });

    test('hub_summary_text_joins_nonzero', () async {
      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': true,
          'problems': {
            'out': 2,
            'low': 1,
            'expired': 1,
            'near_expiry': 0,
            'products': 3,
          },
        },
      );

      final summary = await repository.getSummary();

      expect(summary.activated, isTrue);
      expect(summary.problems, isNotNull);
      expect(summary.problems!.count, 3);
      expect(
        summary.problems!.text,
        '2 hết hàng · 1 tồn thấp · 1 có lô hết hạn',
      );
    });

    test('hub_problems_zero_is_null', () async {
      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': true,
          'problems': {
            'out': 0,
            'low': 0,
            'expired': 0,
            'near_expiry': 0,
            'products': 0,
          },
        },
      );

      final summary = await repository.getSummary();

      expect(summary.activated, isTrue);
      expect(summary.problems, isNull);
      expect(summary.openStocktakes, 0);
    });

    test('hub_attention_stocktakes parses stocktakes_open when activated only',
        () async {
      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': true,
          'problems': {
            'out': 0,
            'low': 0,
            'expired': 0,
            'near_expiry': 0,
            'products': 0,
            'stocktakes_open': 2,
          },
        },
      );

      final active = await repository.getSummary();
      expect(active.openStocktakes, 2);

      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': false,
          'problems': {
            'stocktakes_open': 2,
          },
        },
      );

      final inactive = await repository.getSummary();
      expect(inactive.openStocktakes, 0);
    });

    test('hub_attention_programs_reached parses programs_reached when activated only',
        () async {
      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': true,
          'problems': {
            'out': 0,
            'low': 0,
            'expired': 0,
            'near_expiry': 0,
            'products': 0,
            'programs_reached': 2,
          },
        },
      );

      final active = await repository.getSummary();
      expect(active.programsReached, 2);

      when(() => mockRpc.query('get_warehouse_hub_summary')).thenAnswer(
        (_) async => {
          'activated': false,
          'problems': {
            'programs_reached': 2,
          },
        },
      );

      final inactive = await repository.getSummary();
      expect(inactive.programsReached, 0);
    });
  });
}
