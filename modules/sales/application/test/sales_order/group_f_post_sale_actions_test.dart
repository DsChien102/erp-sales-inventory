import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _DenyPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {
    throw const SalesContractException('PERMISSION_DENIED', message: 'Denied in test.');
  }
}

void main() {
  group('TH-05 Group F-ops S21 post-sale actions', () {
    test('available actions returns cancel/return flags and enforces sales.order.view', () async {
      final gateway = FakePostSaleActionsGateway(
        actions: const AvailablePostSaleActionsDto(
          canCancel: false,
          canReturnExchange: true,
        ),
      );
      final handler = GetAvailablePostSaleActionsQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        postSaleActionsGateway: gateway,
      );

      final dto = await handler.handle(
        GetAvailablePostSaleActionsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.canCancel, isFalse);
      expect(dto.canReturnExchange, isTrue);
      expect(gateway.actionsCalls, 1);
    });

    test('available actions enforces sales.order.view before the gateway', () async {
      final gateway = FakePostSaleActionsGateway();
      final handler = GetAvailablePostSaleActionsQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        postSaleActionsGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetAvailablePostSaleActionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.actionsCalls, 0);
    });
  });
}
