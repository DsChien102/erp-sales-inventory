import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  test('scn_e02_u01_fr04_01: resolving completes buyer data and locks completion', () async {
    final gateway = FakeBuyerInvoiceDataGateway(
      context: const BuyerCompletionContext(
        base: BuyerInvoiceSourceFields(
          buyerType: BuyerType.organization,
          name: 'Cty A',
          address: 'HN',
        ),
        completionSource: BuyerInvoiceSourceFields(
          buyerType: BuyerType.organization,
          taxCode: '0101',
        ),
        status: BuyerCompletionStatus.open,
        salesOrderVersion: '3',
        buyerPartnerId: 'bp1',
        eligibleFields: ['taxCode'],
      ),
    );
    final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
    final result = await handler.handle(
      CompleteBuyerInvoiceDataCommand(
        tenantId: 't1',
        actorId: 'a1',
        salesOrderId: 'so1',
        expectedOrderVersion: 3,
      ),
    );
    expect(result.locked, isTrue);
    expect(result.effectiveBuyer.taxCode, '0101');
    expect(gateway.savedResolvedValues?['taxCode'], '0101');
  });

  test(
    'scn_e02_u01_fr08_01: org still missing tax code throws BUYER_TAX_CODE_REQUIRED and does not lock',
    () async {
      final gateway = FakeBuyerInvoiceDataGateway(
        context: const BuyerCompletionContext(
          base: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization,
            name: 'Cty A',
            address: 'HN',
          ),
          status: BuyerCompletionStatus.open,
          salesOrderVersion: '1',
          buyerPartnerId: 'bp1',
          eligibleFields: ['taxCode'],
        ),
      );
      final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
      expect(
        () => handler.handle(
          CompleteBuyerInvoiceDataCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: 'so1',
            expectedOrderVersion: 1,
          ),
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.buyerTaxCodeRequired,
          ),
        ),
      );
      expect(gateway.savedResolvedValues, isNull);
    },
  );

  test(
    'scn_e02_u01_fr08_02: org has tax code but missing address throws BUYER_ADDRESS_REQUIRED',
    () async {
      final gateway = FakeBuyerInvoiceDataGateway(
        context: const BuyerCompletionContext(
          base: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization,
            name: 'Cty A',
            taxCode: '0101',
          ),
          status: BuyerCompletionStatus.open,
          salesOrderVersion: '1',
          buyerPartnerId: 'bp1',
          eligibleFields: ['address'],
        ),
      );
      final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
      expect(
        () => handler.handle(
          CompleteBuyerInvoiceDataCommand(
            tenantId: 't1',
            actorId: 'a1',
            salesOrderId: 'so1',
            expectedOrderVersion: 1,
          ),
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.buyerAddressRequired,
          ),
        ),
      );
      expect(gateway.savedResolvedValues, isNull);
    },
  );

  test(
    'scn_e02_u01_fr04_02: already LOCKED completion applies frozen resolved_values without re-saving',
    () async {
      // base snapshot is incomplete (no tax code) — the frozen completionSource must
      // still be applied so effective is complete; must NOT throw, must NOT re-save.
      final gateway = FakeBuyerInvoiceDataGateway(
        context: const BuyerCompletionContext(
          base: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization,
            name: 'Cty A',
            address: 'HN',
          ),
          completionSource: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization,
            taxCode: '0101',
          ),
          status: BuyerCompletionStatus.locked,
          salesOrderVersion: '5',
          buyerPartnerId: 'bp1',
          eligibleFields: ['taxCode'],
        ),
      );
      final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
      final result = await handler.handle(
        CompleteBuyerInvoiceDataCommand(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so1',
          expectedOrderVersion: 5,
        ),
      );
      expect(result.locked, isTrue);
      expect(result.effectiveBuyer.taxCode, '0101');
      expect(gateway.savedResolvedValues, isNull); // immutable after LOCKED — not re-saved
    },
  );
}
