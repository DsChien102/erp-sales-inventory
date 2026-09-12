import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'package:vet45_sales_infrastructure/src/domain/sales_order/supabase_post_sale_actions_gateway.dart';

void main() {
  group('SupabasePostSaleActionsGateway', () {
    test('S21 available actions maps cancel/return booleans', () async {
      final rpc = _FakeRpcClient(
        response: {'canCancel': false, 'canReturnExchange': true},
      );
      final gateway = SupabasePostSaleActionsGateway(rpcClient: rpc);

      final dto = await gateway.getAvailableActions(
        GetAvailablePostSaleActionsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_available_post_sale_actions');
      expect(rpc.lastParams?['sales_order_id'], 'order-1');
      expect(dto.canCancel, isFalse);
      expect(dto.canReturnExchange, isTrue);
    });

    test('S21 maps NOT_FOUND envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(jsonEncode({'code': 'NOT_FOUND', 'message': 'Not found.'})),
      );
      final gateway = SupabasePostSaleActionsGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getAvailableActions(
          GetAvailablePostSaleActionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-x',
          ),
        ),
        throwsA(isA<SalesContractException>().having((e) => e.code, 'code', 'NOT_FOUND')),
      );
    });

    test('S21 maps STALE_VERSION envelope to SalesContractException', () async {
      final rpc = _FakeRpcClient(
        error: RpcException(jsonEncode({'code': 'STALE_VERSION', 'message': 'Stale.'})),
      );
      final gateway = SupabasePostSaleActionsGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getAvailableActions(
          GetAvailablePostSaleActionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 2,
          ),
        ),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'STALE_VERSION'),
        ),
      );
    });

    test('S21 maps malformed result to DEPENDENCY_UNAVAILABLE', () async {
      final rpc = _FakeRpcClient(response: {'canCancel': 'not-a-bool'});
      final gateway = SupabasePostSaleActionsGateway(rpcClient: rpc);

      await expectLater(
        () => gateway.getAvailableActions(
          GetAvailablePostSaleActionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
        ),
      );
    });
  });
}

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}
