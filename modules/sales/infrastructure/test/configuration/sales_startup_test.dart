import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

void main() {
  group('SalesStartup', () {
    test('answers Group A pricing preview through the query bus', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      final preview = await module.executeQueryAsync<PricingPreviewDto>(
        PreviewSalesPricingQuery(
          tenantId: 'tenant-1',
          workingState: SalesOrderWorkingStateDto(
            store: const StoreSnapshotDto(
              storeId: 'store-1',
              storeCode: 'S01',
              displayName: 'Store 1',
            ),
            currencyCode: 'VND',
            lines: const [
              CheckoutLineInput(
                productId: 'product-1',
                productUnitId: 'unit-1',
                quantity: QuantityDto(quantityMicros: QuantityDto.scale),
                unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
              ),
            ],
          ),
        ),
      );

      expect(module, isA<ISalesModule>());
      expect(preview.summary.grandTotal.amountMinor, 100000);
    });

    test('S12 finalize command handler is registered and runs command-time precheck', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
        checkoutGateway: _BlockedCheckoutGateway(),
      );

      // Precheck fails closed (canFinalize=false); the authoritative commit is
      // not attempted and the command returns a blocked result. This proves the
      // handler is registered and reachable through the command bus.
      final result = await module.executeCommandAsync<CheckoutResultDto>(
        FinalizeSalesOrderCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          customerId: 'customer-1',
          currencyCode: 'VND',
          lines: const [
            CheckoutLineInput(
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
              unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            ),
          ],
          paymentIntents: const [
            PaymentIntentInput(
              method: SalesPaymentMethod.cash,
              amount: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            ),
          ],
          commercialSnapshot: _commercialSnapshot(),
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          correlationId: 'corr-1',
        ),
      );

      expect(result.status, CheckoutResultStatus.blocked);
    });

    test('S12 checkout attempt status query handler is wired to the gateway', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      // The status handler reaches the Supabase gateway directly; against an
      // unavailable RPC endpoint the gateway maps the failure to a stable
      // SalesContractException, proving handler + gateway wiring.
      await expectLater(
        () => module.executeQueryAsync<CheckoutResultDto>(
          GetCheckoutResultQuery(
            storeId: 'store-1',
tenantId: 'tenant-1',
            actorId: 'actor-1',
            idempotencyKey: 'attempt-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S13 get sales order query handler is wired to the read gateway', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      await expectLater(
        () => module.executeQueryAsync<SalesOrderResultDto>(
          GetSalesOrderQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: 'order-1'),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S14 generate sales receipt command handler is wired to the receipt gateway', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      await expectLater(
        () => module.executeCommandAsync<SalesReceiptDto>(
          GenerateSalesReceiptCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            idempotencyKey: 'idem-1',
            payloadHash: 'hash-1',
            correlationId: 'corr-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S15-S18 inquiry query handlers are wired to the inquiry gateway', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      await expectLater(
        () => module.executeQueryAsync<PagedSalesOrderListDto>(
          ListSalesOrdersQuery(tenantId: 'tenant-1', actorId: 'actor-1'),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<SalesOrderDetailDto>(
          GetSalesOrderDetailQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<SalesOrderSettlementDto>(
          GetSalesOrderSettlementQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<SalesOrderTimelineDto>(
          GetSalesOrderTimelineQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('S21 post-sale action handlers are wired to the post-sale gateway', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      await expectLater(
        () => module.executeQueryAsync<AvailablePostSaleActionsDto>(
          GetAvailablePostSaleActionsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('Group H S23/S25/S27 reach gateways via ISalesModule', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      // Against an unavailable example endpoint each use case must reach its
      // gateway and throw SalesContractException — proving DI + codegen wiring
      // rather than a missing-handler failure.
      await expectLater(
        () => module.executeQueryAsync<CancellationPrecheckDto>(
          PrecheckSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeCommandAsync<SalesOrderCancellationResultDto>(
          ConfirmSalesOrderCancellationCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            reason: const CancellationReasonDto(
              reasonText: 'Customer request',
            ),
            idempotencyKey: 'idem-1',
            payloadHash: 'hash-1',
            correlationId: 'corr-1',
            expectedVersion: 1,
            expectedSettlementVersion: 1,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<SalesOrderCancellationDetailDto>(
          GetSalesOrderCancellationQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<List<CancellationReasonPolicyDto>>(
          ListSalesOrderCancellationReasonsQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });

    test('Group I S28–S33 ports register concrete Supabase/unavailable adapters', () {
      final container = GetIt.asNewInstance();
      SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
        container: container,
      );

      expect(
        container.get<IReturnExchangeReadGateway>(),
        isA<SupabaseReturnExchangeReadGateway>(),
      );
      expect(
        container.get<IReturnExchangeCommandGateway>(),
        isA<SupabaseReturnExchangeCommandGateway>(),
      );
      expect(
        container.get<IReturnExchangeSettlementGateway>(),
        isA<SupabaseReturnExchangeSettlementGateway>(),
      );
      expect(
        container.get<IReturnExchangeReferencePort>(),
        isA<UnavailableReturnExchangeReferencePort>(),
      );
    });

    test('Group I S28–S34 handlers reach return-exchange gateways via ISalesModule', () async {
      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      await expectLater(
        () => module.executeQueryAsync<ReturnExchangePrecheckDto>(
          PrecheckReturnExchangeQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<ReturnableOrderLinesDto>(
          GetReturnableOrderLinesQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<ReturnExchangeFormPolicyDto>(
          GetReturnExchangeFormPolicyQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<ReturnExchangeDetailDto>(
          GetReturnExchangeDetailQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeCommandAsync<ReturnExchangeDraftDto>(
          StartReturnExchangeCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            entrySource: ReturnExchangeEntrySource.standard,
            lines: const [
              ReturnExchangeLineInput(
                kind: ReturnExchangeLineKind.returnLine,
                productId: 'product-1',
                productUnitId: 'unit-1',
                quantity: QuantityDto(quantityMicros: QuantityDto.scale),
                originalSalesOrderLineId: 'line-1',
                reasonCode: 'DAMAGED',
                conditionCode: 'OPENED',
              ),
            ],
            idempotencyKey: 'idem-1',
            payloadHash: 'hash-1',
            correlationId: 'corr-1',
            expectedVersion: 1,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeQueryAsync<ReturnExchangeValuationDto>(
          EvaluateReturnPricingImpactQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            expectedSourceVersion: 1,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeCommandAsync<ReturnExchangeResultDto>(
          ConfirmReturnExchangeCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            idempotencyKey: 'idem-c',
            payloadHash: 'hash-c',
            correlationId: 'corr-c',
            expectedVersion: 1,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      await expectLater(
        () => module.executeCommandAsync<ReturnExchangeResultDto>(
          CompleteReturnExchangeCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            idempotencyKey: 'idem-d',
            payloadHash: 'hash-d',
            correlationId: 'corr-d',
            expectedVersion: 1,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
    });
  });
}

final class _BlockedCheckoutGateway implements ICheckoutGateway {
  @override
  Future<CheckoutPrecheckDto> precheck(PrecheckSalesOrderCheckoutQuery query) async {
    return CheckoutPrecheckDto(
      canFinalize: false,
      blockers: const [
        SalesBlockerDto(code: 'DEPENDENCY_UNAVAILABLE', message: 'Blocked in test.'),
      ],
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

  @override
  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command) {
    throw StateError('finalize must not run when precheck is blocked');
  }

  @override
  Future<CheckoutResultDto> getResult(
    GetCheckoutResultQuery query,
  ) {
    throw UnimplementedError();
  }
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
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
  lines: const [
    SalesReceiptLineDto(
      lineId: 'line-1',
      product: ProductSnapshotDto(
        productId: 'product-1',
        sku: null,
        displayName: 'Vaccine A',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-1',
        unitCode: null,
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
);
