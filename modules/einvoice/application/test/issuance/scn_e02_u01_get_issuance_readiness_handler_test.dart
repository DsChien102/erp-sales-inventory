import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  IssuanceReadinessInput ready() => const IssuanceReadinessInput(
    orderCompleted: true,
    hasElectronicInvoice: false,
    hasActiveOperation: false,
    configReady: true,
    providerConnected: true,
    providerSupportsPreview: true,
    buyer: EffectiveBuyerInvoiceData(
      buyerType: BuyerType.retail,
      name: 'NTD',
    ),
    buyerCompletionState: BuyerCompletionStatus.locked,
  );

  test('scn_e02_u01_fr01_01: ready order maps to READY dto with no blockers', () async {
    final handler = GetIssuanceReadinessQueryHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(result: ready()),
    );
    final dto = await handler.handle(
      GetIssuanceReadinessQuery(
        tenantId: 't1',
        actorId: 'a1',
        salesOrderId: 'so1',
      ),
    );
    expect(dto.level, IssuanceReadinessLevel.ready);
    expect(dto.blockers, isEmpty);
    expect(dto.buyerCompletionState, BuyerCompletionStatus.locked);
  });

  test(
    'scn_e02_u01_fr10_01: org missing tax code surfaces BUYER_TAX_CODE_REQUIRED blocker',
    () async {
      const input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Cty A',
          address: 'HN',
        ),
        buyerCompletionState: BuyerCompletionStatus.locked,
      );
      final handler = GetIssuanceReadinessQueryHandler(
        readinessGateway: FakeIssuanceReadinessReadGateway(result: input),
      );
      final dto = await handler.handle(
        GetIssuanceReadinessQuery(
          tenantId: 't1',
          actorId: 'a1',
          salesOrderId: 'so1',
        ),
      );
      expect(dto.level, IssuanceReadinessLevel.notReady);
      expect(
        dto.blockers.map((b) => b.code),
        contains(EInvoiceBlockedCodes.buyerTaxCodeRequired),
      );
    },
  );
}
