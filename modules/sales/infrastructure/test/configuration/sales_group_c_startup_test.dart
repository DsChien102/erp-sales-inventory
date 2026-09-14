import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

void main() {
  group('SalesStartup Group C', () {
    test('production registrar injects checkout gateway into Group C query handler', () async {
      final gateway = _RecordingCheckoutGateway(result: _readyResult());
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        checkoutGateway: gateway,
      );

      final result = await module.executeQueryAsync(
        PrecheckSalesOrderCheckoutQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          customerId: 'customer-1',
          currencyCode: 'VND',
          lines: const <CheckoutLineInput>[
            CheckoutLineInput(
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
              unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            ),
          ],
          paymentIntents: const <PaymentIntentInput>[],
        ),
      );

      expect(result.canFinalize, isTrue);
      expect(gateway.precheckCount, 1);
    });
  });
}

CheckoutPrecheckDto _readyResult() {
  return CheckoutPrecheckDto(
    canFinalize: true,
    blockers: const <SalesBlockerDto>[],
    monetarySummary: const CheckoutMonetarySummaryDto(
      subtotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      grandTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
    receivableRequirement: const ReceivableRequirementDto(
      isRequired: false,
      amount: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    ),
  );
}

final class _RecordingCheckoutGateway implements ICheckoutGateway {
  _RecordingCheckoutGateway({required this.result});

  final CheckoutPrecheckDto result;
  PrecheckSalesOrderCheckoutQuery? precheckCalls;
  int precheckCount = 0;

  @override
  Future<CheckoutPrecheckDto> precheck(PrecheckSalesOrderCheckoutQuery query) async {
    precheckCalls = query;
    precheckCount += 1;
    return result;
  }

  @override
  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command) {
    throw UnsupportedError('finalize is Group D; Group C must not reach it');
  }

  @override
  Future<CheckoutResultDto> getResult(GetCheckoutResultQuery query) {
    throw UnsupportedError('getResult is Group D; Group C must not reach it');
  }
}
