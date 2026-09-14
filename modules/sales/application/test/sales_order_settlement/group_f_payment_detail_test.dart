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
  group('TH-05 Group F-read S17 payment detail', () {
    test('S17 settlement returns independent totals, refunded and optional dueAt', () async {
      final gateway = FakeSalesOrderInquiryGateway(
        settlement: SalesOrderSettlementDto(
          settlementId: 'settlement-1',
          salesOrderId: 'order-1',
          version: 3,
          status: SalesSettlementStatus.partiallyPaid,
          orderTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: const MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
          refundedTotal: const MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
          outstanding: const MoneyDto(amountMinor: 650000, currencyCode: 'VND'),
          dueAt: DateTime.utc(2026, 8, 30),
        ),
      );
      final handler = GetSalesOrderSettlementQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final dto = await handler.handle(
        GetSalesOrderSettlementQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(dto.settlementId, 'settlement-1');
      expect(dto.version, 3);
      expect(dto.status, SalesSettlementStatus.partiallyPaid);
      expect(dto.orderTotal.amountMinor, 1000000);
      expect(dto.paidTotal.amountMinor, 400000);
      expect(dto.refundedTotal.amountMinor, 50000);
      expect(dto.outstanding.amountMinor, 650000);
      expect(dto.dueAt, DateTime.utc(2026, 8, 30));
      expect(gateway.settlementCalls, 1);
    });

    test('S17 payment transactions preserves cursor and pageSize in withExecutionContext', () {
      final query = GetSalesOrderPaymentTransactionsQuery(
        salesOrderId: 'order-1',
        expectedSourceVersion: 7,
        cursor: '2026-08-07T00:00:00.000Z|txn-1',
        pageSize: 10,
      );

      final scoped = query.withExecutionContext(tenantId: 'tenant-1', actorId: 'actor-1');

      expect(scoped.tenantId, 'tenant-1');
      expect(scoped.actorId, 'actor-1');
      expect(scoped.salesOrderId, 'order-1');
      expect(scoped.expectedSourceVersion, 7);
      expect(scoped.cursor, '2026-08-07T00:00:00.000Z|txn-1');
      expect(scoped.pageSize, 10);
    });

    test('S17 payment transactions returns a cursor page', () async {
      final gateway = FakeSalesOrderInquiryGateway(
        transactions: SalesPaymentTransactionsDto(
          page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
            items: [
              SalesPaymentTransactionDto(
                transactionId: 'txn-1',
                method: SalesPaymentMethod.cash,
                amount: const MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
                status: SalesPaymentStatus.confirmed,
                recordedAt: DateTime.utc(2026, 8, 7),
                transactionType: SalesPaymentTransactionType.collection,
                direction: SalesPaymentDirection.inflow,
                actorId: 'actor-1',
              ),
            ],
            hasMore: true,
            nextCursor: '2026-08-07T00:00:00.000Z|txn-1',
          ),
        ),
      );
      final handler = GetSalesOrderPaymentTransactionsQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        inquiryGateway: gateway,
      );

      final dto = await handler.handle(
        GetSalesOrderPaymentTransactionsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          cursor: null,
          pageSize: 25,
        ),
      );

      expect(dto.page.items.single.transactionId, 'txn-1');
      expect(dto.page.items.single.transactionType, SalesPaymentTransactionType.collection);
      expect(dto.page.items.single.direction, SalesPaymentDirection.inflow);
      expect(dto.page.items.single.actorId, 'actor-1');
      expect(dto.page.hasMore, isTrue);
      expect(dto.page.nextCursor, '2026-08-07T00:00:00.000Z|txn-1');
      expect(gateway.transactionsCalls, 1);
    });

    test('S17 settlement enforces sales.payment.view before the gateway', () async {
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = GetSalesOrderSettlementQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        inquiryGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetSalesOrderSettlementQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.settlementCalls, 0);
    });

    test('S17 payment transactions enforces sales.payment.view before the gateway', () async {
      final gateway = FakeSalesOrderInquiryGateway();
      final handler = GetSalesOrderPaymentTransactionsQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        inquiryGateway: gateway,
      );

      await expectLater(
        () => handler.handle(
          GetSalesOrderPaymentTransactionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.transactionsCalls, 0);
    });
  });
}
