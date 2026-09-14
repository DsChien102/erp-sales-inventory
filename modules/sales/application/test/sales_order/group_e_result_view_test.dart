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
  group('TH-05 Group E S13 result view reads', () {
    test('SCN-01 fully paid order returns paid summary with zero outstanding', () async {
      final gateway = FakeSalesOrderReadGateway(
        result: _salesOrderResult,
        paymentSummary: SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.paid,
          orderTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      );
      final handler = GetSalesOrderPaymentSummaryQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        readGateway: gateway,
      );

      final dto = await handler.handle(_paymentQuery());

      expect(dto.status, SalesSettlementStatus.paid);
      expect(dto.outstandingTotal.amountMinor, 0);
      expect(gateway.paymentCalls, 1);
    });

    test('SCN-02 partially paid order returns non-zero outstanding', () async {
      final gateway = FakeSalesOrderReadGateway(
        result: _salesOrderResult,
        paymentSummary: SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.partiallyPaid,
          orderTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
          outstandingTotal: MoneyDto(amountMinor: 600000, currencyCode: 'VND'),
          dueAt: DateTime.utc(2026, 8, 30),
        ),
      );
      final handler = GetSalesOrderPaymentSummaryQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        readGateway: gateway,
      );

      final dto = await handler.handle(_paymentQuery());

      expect(dto.status, SalesSettlementStatus.partiallyPaid);
      expect(dto.outstandingTotal.amountMinor, 600000);
      expect(dto.dueAt, DateTime.utc(2026, 8, 30));
    });

    test('SCN-01 order query returns the committed commercial result', () async {
      final gateway = FakeSalesOrderReadGateway(result: _salesOrderResult);
      final handler = GetSalesOrderQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        readGateway: gateway,
      );

      final dto = await handler.handle(_orderQuery());

      expect(dto, same(_salesOrderResult));
      expect(dto.order.orderNumber, 'SO-000129');
      expect(dto.store.displayName, 'Chi nhánh Quận 1');
      expect(dto.seller.displayName, 'Minh Anh');
      expect(gateway.orderCalls, 1);
    });

    test('checkout result view composes the order result client-side', () {
      final view = CheckoutResultViewDto(
        checkout: const CheckoutResultDto(
          idempotencyKey: 'attempt-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 3,
          status: CheckoutResultStatus.succeeded,
        ),
        order: _salesOrderResult,
        payment: const SalesOrderPaymentSummaryDto(
          status: SalesSettlementStatus.paid,
          orderTotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
          paidTotal: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
          outstandingTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      );

      expect(view.order, same(_salesOrderResult));
    });

    test('order query enforces sales.order.view before the gateway', () async {
      final gateway = FakeSalesOrderReadGateway(result: _salesOrderResult);
      final handler = GetSalesOrderQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        readGateway: gateway,
      );

      await expectLater(
        () => handler.handle(_orderQuery()),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.orderCalls, 0);
    });

    test('payment summary query enforces sales.payment.view before the gateway', () async {
      final gateway = FakeSalesOrderReadGateway(result: _salesOrderResult);
      final handler = GetSalesOrderPaymentSummaryQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        readGateway: gateway,
      );

      await expectLater(
        () => handler.handle(_paymentQuery()),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.paymentCalls, 0);
    });
  });
}

final _salesOrderResult = SalesOrderResultDto(
  order: const SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-000129',
    version: 3,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12, 2, 41),
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyễn Văn An',
    phoneNumber: '0903456789',
  ),
);

GetSalesOrderQuery _orderQuery() =>
    GetSalesOrderQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1');

GetSalesOrderPaymentSummaryQuery _paymentQuery() => GetSalesOrderPaymentSummaryQuery(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
);
