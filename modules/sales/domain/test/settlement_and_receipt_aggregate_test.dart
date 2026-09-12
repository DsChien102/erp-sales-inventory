import 'package:test/test.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_sales_domain/enums.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('SalesOrderSettlement', () {
    test('initialize and record payment update summary', () {
      final settlement = SalesOrderSettlement.initialize(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        orderGrandTotal: Money(amountMinor: 100000, currencyCode: 'VND'),
        customer: CustomerRefSnapshot(
          customerId: 'c1',
          displayName: 'Customer',
          isWalkIn: false,
        ),
        initialCollections: [
          SalesPaymentTransaction(
            id: const SalesPaymentTransactionId('tx-1'),
            kind: SalesPaymentTransactionKind.collection,
            method: SalesPaymentMethod.cash,
            amount: Money(amountMinor: 40000, currencyCode: 'VND'),
            status: SalesPaymentStatus.confirmed,
          ),
        ],
      );
      expect(settlement.status, SalesSettlementStatus.partiallyPaid);
      expect(
        settlement.domainEvents!.first,
        isA<SalesOrderSettlementInitializedEvent>(),
      );

      settlement.recordPayment(
        method: SalesPaymentMethod.cash,
        amount: Money(amountMinor: 60000, currencyCode: 'VND'),
      );
      expect(settlement.status, SalesSettlementStatus.paid);
      expect(settlement.summary.outstanding.isZero, isTrue);
    });

    test('S12 initializes settlement with initial checkout payment', () {
      final settlement = SalesOrderSettlement.initializeForOrder(
        id: const SalesOrderSettlementId('settlement-1'),
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        grandTotalMinor: 100000,
        currencyCode: 'VND',
        customer: CustomerRefSnapshot(
          customerId: 'c1',
          displayName: 'Customer',
          isWalkIn: false,
        ),
        payments: [
          SalesPaymentTransaction.recordInitial(
            id: const SalesPaymentTransactionId('tx-1'),
            amountMinor: 100000,
            currencyCode: 'VND',
            method: SalesPaymentMethod.cash,
          ),
        ],
      );

      expect(settlement.id.value, 'settlement-1');
      expect(settlement.status, SalesSettlementStatus.paid);
      expect(settlement.summary.outstanding.isZero, isTrue);
      expect(settlement.transactions, hasLength(1));
      expect(
        settlement.transactions.single.kind,
        SalesPaymentTransactionKind.collection,
      );
    });

    test('walk-in cannot leave outstanding receivable', () {
      expect(
        () => SalesOrderSettlement.initialize(
          tenantId: const TenantId('t1'),
          salesOrderId: 'order-1',
          orderGrandTotal: Money(amountMinor: 100000, currencyCode: 'VND'),
          customer: CustomerRefSnapshot(
            displayName: 'Walk-in',
            isWalkIn: true,
          ),
          initialCollections: const [],
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('refund cannot exceed collected', () {
      final settlement = SalesOrderSettlement.initialize(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        orderGrandTotal: Money(amountMinor: 100000, currencyCode: 'VND'),
        customer: CustomerRefSnapshot(
          customerId: 'c1',
          displayName: 'Customer',
          isWalkIn: false,
        ),
        initialCollections: [
          SalesPaymentTransaction(
            id: const SalesPaymentTransactionId('tx-1'),
            kind: SalesPaymentTransactionKind.collection,
            method: SalesPaymentMethod.cash,
            amount: Money(amountMinor: 100000, currencyCode: 'VND'),
            status: SalesPaymentStatus.confirmed,
          ),
        ],
      );
      expect(
        () => settlement.recordRefund(
          method: SalesPaymentMethod.cash,
          amount: Money(amountMinor: 100001, currencyCode: 'VND'),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('SalesReceipt', () {
    test('generate and print', () {
      final receipt = SalesReceipt.generate(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        contentHash: 'hash-1',
      );
      expect(receipt.status, SalesReceiptStatus.generated);
      receipt.recordPrinted();
      expect(receipt.activities, hasLength(1));
      receipt.archive();
      expect(receipt.status, SalesReceiptStatus.archived);
      expect(
        () => receipt.recordShared(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('print and share keep content hash and reject superseded receipts', () {
      final generated = SalesReceipt.generate(
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        contentHash: 'hash-1',
      );
      generated.recordPrinted();
      generated.recordShared();
      expect(generated.contentHash, 'hash-1');
      expect(generated.activities, hasLength(2));

      final superseded = SalesReceipt.reconstitute(
        id: generated.id,
        tenantId: generated.tenantId,
        salesOrderId: generated.salesOrderId,
        contentHash: generated.contentHash,
        versionNumber: generated.versionNumber,
        status: SalesReceiptStatus.superseded,
        activities: generated.activities,
        version: generated.version,
      );
      expect(
        () => superseded.recordPrinted(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(
        () => superseded.recordShared(),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      expect(superseded.contentHash, 'hash-1');
    });

    test('archive is allowed from superseded and is a no-op when already archived', () {
      final superseded = SalesReceipt.reconstitute(
        id: const SalesReceiptId('receipt-1'),
        tenantId: const TenantId('t1'),
        salesOrderId: 'order-1',
        contentHash: 'hash-1',
        versionNumber: 2,
        status: SalesReceiptStatus.superseded,
        activities: const [],
        version: 2,
      );
      superseded.archive();
      expect(superseded.status, SalesReceiptStatus.archived);
      expect(superseded.contentHash, 'hash-1');
      final versionAfterArchive = superseded.version;
      superseded.archive();
      expect(superseded.status, SalesReceiptStatus.archived);
      expect(superseded.version, versionAfterArchive);
    });
  });
}
