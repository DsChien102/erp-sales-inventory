import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_sales_domain/domain.dart';

void main() {
  group('TH-05 contract foundation', () {
    test('uses exact money and quantity representations', () {
      const money = MoneyDto(amountMinor: 125000, currencyCode: 'VND');
      const quantity = QuantityDto(quantityMicros: 1500000);

      expect(money.amountMinor, 125000);
      expect(money.currencyCode, 'VND');
      expect(quantity.quantityMicros, 1500000);
    });

    test('exports canonical permissions without the legacy refund alias', () {
      expect(SalesPermissions.createDraft, 'sales.draft.create');
      expect(SalesPermissions.finalizeCheckout, 'sales.checkout.create');
      expect(SalesPermissions.refundPayment, 'sales.payment.refund');
    });

    test('keeps lifecycle dimensions separate', () {
      expect(
        SalesDraftStatus.values.map((value) => value.name),
        <String>['active', 'converted', 'cancelled', 'expired'],
      );
      expect(
        CheckoutResultStatus.values.map((value) => value.name),
        <String>[
          'processing',
          'succeeded',
          'blocked',
          'failed',
          'uncertain',
        ],
      );
      expect(
        SalesOrderLifecycleStatus.values.map((value) => value.name),
        <String>['completed', 'cancelled'],
      );
      expect(
        SalesOrderLockStatus.values.map((value) => value.name),
        <String>['unlocked', 'locked'],
      );
      expect(
        SalesSettlementStatus.values.map((value) => value.name),
        <String>[
          'unpaid',
          'partiallyPaid',
          'paid',
          'partiallyRefunded',
          'refunded',
          'noBalance',
        ],
      );
      expect(
        SalesPaymentMethod.values.map((value) => value.name),
        <String>['cash', 'manualBankTransfer'],
      );
      expect(
        SalesPaymentStatus.values.map((value) => value.name),
        <String>['pending', 'confirmed', 'failed', 'voided'],
      );
      expect(
        SalesOrderCancellationStatus.values.map((value) => value.name),
        <String>[
          'requested',
          'validating',
          'confirmed',
          'processing',
          'completed',
          'blocked',
          'failed',
          'cancelled',
        ],
      );
      expect(
        ReturnExchangeStatus.values.map((value) => value.name),
        <String>[
          'draft',
          'confirmed',
          'processing',
          'completed',
          'cancelled',
          'blocked',
          'failed',
        ],
      );
      expect(
        SalesReceiptStatus.values.map((value) => value.name),
        <String>['generated', 'superseded', 'archived'],
      );
      expect(
        IntegrationDeliveryStatus.values.map((value) => value.name),
        <String>[
          'notRequired',
          'queued',
          'delivered',
          'retryScheduled',
          'failed',
          'deadLetter',
          'unknown',
        ],
      );
    });

    test('registers every canonical fake scenario id exactly once', () {
      expect(SalesFakeScenarioRegistry.ids, hasLength(209));
      expect(SalesFakeScenarioRegistry.ids.toSet(), hasLength(209));
      expect(
        SalesFakeScenarioRegistry.ids,
        contains('e01_u01_scn01_khoi_tao_don_moi_voi_khach_le'),
      );
      expect(
        SalesFakeScenarioRegistry.ids,
        contains('e06_u04_scn04_bo_thay_doi_release_reservation'),
      );
      expect(
        SalesFakeScenarioRegistry.ids,
        contains('e06_u07_scn07_downstream_inventory_failed'),
      );
    });
  });
}
