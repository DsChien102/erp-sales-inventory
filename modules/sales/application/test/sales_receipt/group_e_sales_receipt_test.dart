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
  group('TH-05 Group E S14 sales receipt', () {
    test('SCN-01 generate produces a receipt referencing the sales order', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GenerateSalesReceiptCommandHandler(receiptGateway: gateway);

      final dto = await handler.handle(_generateCommand());

      expect(dto.salesOrderId, 'order-1');
      expect(dto.status, SalesReceiptStatus.generated);
      expect(dto.document.receiptNumber, 'PBH-20260812-0129');
      expect(gateway.generateCalls, 1);
    });

    test(
      'SCN-07 repeated generate with same idempotency context returns the existing receipt',
      () async {
        final gateway = FakeSalesReceiptGateway(receipt: _receipt);
        final handler = GenerateSalesReceiptCommandHandler(receiptGateway: gateway);

        final first = await handler.handle(_generateCommand());
        final second = await handler.handle(_generateCommand());

        expect(first.receiptId, second.receiptId);
        expect(first.version, second.version);
        expect(first.document, same(second.document));
        expect(gateway.generateCalls, 2);
      },
    );

    test('SCN-03 record printed forwards to the gateway once', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = RecordSalesReceiptPrintedCommandHandler(receiptGateway: gateway);

      final dto = await handler.handle(_printedCommand());

      expect(dto.receiptId, 'receipt-1');
      expect(gateway.printedCalls, 1);
    });

    test('SCN-04 record shared forwards to the gateway once', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = RecordSalesReceiptSharedCommandHandler(receiptGateway: gateway);

      final dto = await handler.handle(_sharedCommand());

      expect(dto.receiptId, 'receipt-1');
      expect(gateway.sharedCalls, 1);
    });

    test('archive returns the injected receipt', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = ArchiveSalesReceiptCommandHandler(receiptGateway: gateway);

      final dto = await handler.handle(_archiveCommand());

      expect(dto, same(_receipt));
      expect(gateway.archiveCalls, 1);
    });

    test('SCN-02 get receipt returns the generated receipt for a permitted user', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesReceiptQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        receiptGateway: gateway,
      );

      final dto = await handler.handle(_getReceiptQuery());

      expect(dto.receiptId, 'receipt-1');
      expect(gateway.getCalls, 1);
    });

    test('printed activity can fail independently of a successful receipt read', () async {
      final gateway = FakeSalesReceiptGateway(
        receipt: _receipt,
        printedError: const SalesContractException('DEVICE_UNAVAILABLE'),
      );
      final getHandler = GetSalesReceiptQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        receiptGateway: gateway,
      );
      final printedHandler = RecordSalesReceiptPrintedCommandHandler(
        receiptGateway: gateway,
      );

      expect(await getHandler.handle(_getReceiptQuery()), same(_receipt));
      await expectLater(
        () => printedHandler.handle(_printedCommand()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'DEVICE_UNAVAILABLE',
          ),
        ),
      );
    });

    test('get receipt query enforces sales.receipt.view before the gateway', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesReceiptQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        receiptGateway: gateway,
      );

      await expectLater(
        () => handler.handle(_getReceiptQuery()),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getCalls, 0);
    });

    test('original receipt query returns the as-sold document', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesOrderOriginalReceiptQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        receiptGateway: gateway,
      );

      final document = await handler.handle(
        GetSalesOrderOriginalReceiptQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(document.receiptNumber, 'PBH-20260812-0129');
      expect(gateway.getOriginalCalls, 1);
      expect(gateway.generateCalls, 0);
    });

    test('original receipt query enforces receipt view permission', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesOrderOriginalReceiptQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        receiptGateway: gateway,
      );

      await expectLater(
        handler.handle(
          GetSalesOrderOriginalReceiptQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getOriginalCalls, 0);
    });

    test('original order total stays independent of settlement adjustment', () async {
      final receipt = SalesReceiptDto(
        receiptId: 'receipt-return',
        salesOrderId: 'order-1',
        version: 2,
        status: SalesReceiptStatus.generated,
        generatedAt: DateTime.utc(2026, 8, 12, 4, 0),
        document: SalesReceiptDocumentDto(
          receiptNumber: 'PBH-20260812-0003',
          orderNumber: 'SO-0003',
          soldAt: DateTime.utc(2026, 8, 12, 4, 0),
          store: const StoreSnapshotDto(
            storeId: 'store-1',
            storeCode: 'HCM-01',
            displayName: 'Chi nhánh Quận 1',
          ),
          seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
          lines: _receipt.document.lines,
          subtotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          orderTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          paidTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          outstandingTotal: const MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
          payments: const <PaymentIntentSummaryDto>[],
          settlementSnapshot: const SalesReceiptSettlementSnapshotDto(
            originalPayable: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            adjustment: MoneyDto(amountMinor: -200000, currencyCode: 'VND'),
            currentPayable: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
            collected: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            refunded: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            netCollected: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            outstanding: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
          ),
        ),
      );
      final gateway = FakeSalesReceiptGateway(receipt: receipt);
      final handler = GenerateSalesReceiptCommandHandler(receiptGateway: gateway);

      final dto = await handler.handle(_generateCommand());

      expect(dto.document.orderTotal.amountMinor, 1000000);
      expect(dto.document.settlementSnapshot?.adjustment.amountMinor, -200000);
      expect(dto.document.settlementSnapshot?.currentPayable.amountMinor, 800000);
    });

    test('generate surfaces a dependency failure as SalesContractException', () async {
      final gateway = FakeSalesReceiptGateway(
        receipt: _receipt,
        generateError: const SalesContractException(
          'DEPENDENCY_UNAVAILABLE',
          message: 'RPC down.',
        ),
      );
      final handler = GenerateSalesReceiptCommandHandler(receiptGateway: gateway);

      await expectLater(
        () => handler.handle(_generateCommand()),
        throwsA(
          isA<SalesContractException>().having((e) => e.code, 'code', 'DEPENDENCY_UNAVAILABLE'),
        ),
      );
    });
  });
}

final _receipt = SalesReceiptDto(
  receiptId: 'receipt-1',
  salesOrderId: 'order-1',
  version: 1,
  status: SalesReceiptStatus.generated,
  generatedAt: DateTime.utc(2026, 8, 12, 2, 41),
  document: SalesReceiptDocumentDto(
    receiptNumber: 'PBH-20260812-0129',
    orderNumber: 'SO-000129',
    soldAt: DateTime.utc(2026, 8, 12, 2, 41),
    store: const StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: 'Chi nhánh Quận 1',
    ),
    seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
    customer: const CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: 'Nguyễn Văn An',
    ),
    lines: const <SalesReceiptLineDto>[
      SalesReceiptLineDto(
        lineId: 'line-1',
        product: ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-001',
          displayName: 'Vaccine A',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'VIAL',
          unitName: 'Lọ',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      ),
    ],
    subtotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    orderTotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    paidTotal: const MoneyDto(amountMinor: 60000, currencyCode: 'VND'),
    outstandingTotal: const MoneyDto(amountMinor: 40000, currencyCode: 'VND'),
    payments: const <PaymentIntentSummaryDto>[
      PaymentIntentSummaryDto(
        method: SalesPaymentMethod.cash,
        amount: MoneyDto(amountMinor: 60000, currencyCode: 'VND'),
        status: SalesPaymentStatus.confirmed,
      ),
    ],
    dueAt: DateTime.utc(2026, 8, 30),
  ),
);

GenerateSalesReceiptCommand _generateCommand() => GenerateSalesReceiptCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  salesOrderId: 'order-1',
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
);

RecordSalesReceiptPrintedCommand _printedCommand() => RecordSalesReceiptPrintedCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  receiptId: 'receipt-1',
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
);

RecordSalesReceiptSharedCommand _sharedCommand() => RecordSalesReceiptSharedCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  receiptId: 'receipt-1',
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
);

ArchiveSalesReceiptCommand _archiveCommand() => ArchiveSalesReceiptCommand(
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  receiptId: 'receipt-1',
  idempotencyKey: 'idem-1',
  payloadHash: 'hash-1',
  correlationId: 'corr-1',
);

GetSalesReceiptQuery _getReceiptQuery() =>
    GetSalesReceiptQuery(tenantId: 'tenant-1', actorId: 'actor-1', receiptId: 'receipt-1');
