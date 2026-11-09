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
  });
}
