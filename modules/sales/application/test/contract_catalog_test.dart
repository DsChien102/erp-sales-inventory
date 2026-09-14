import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';
import 'package:vet45_sales_domain/domain.dart';

void main() {
  group('TH-05 frozen contract catalog', () {
    test('exports every Sales-owned command', () {
      const commandTypes = <Type>[
        SaveSalesOrderDraftCommand,
        UpdateSalesOrderDraftCommand,
        CancelSalesOrderDraftCommand,
        FinalizeSalesOrderCommand,
        InitializeSalesOrderSettlementCommand,
        RecordSalesPaymentCommand,
        GenerateSalesReceiptCommand,
        RecordSalesReceiptPrintedCommand,
        RecordSalesReceiptSharedCommand,
        ArchiveSalesReceiptCommand,
        ConfirmSalesOrderCancellationCommand,
        StartReturnExchangeCommand,
        UpdateReturnExchangeCommand,
        CancelReturnExchangeCommand,
        ConfirmReturnExchangeCommand,
        CompleteReturnExchangeCommand,
        RecordSalesRefundCommand,
      ];

      expect(commandTypes, hasLength(17));
    });

    test('exports every Sales-owned query', () {
      const queryTypes = <Type>[
        PreviewSalesPricingQuery,
        PrecheckSalesOrderCheckoutQuery,
        ListSalesOrderDraftsQuery,
        GetSalesOrderDraftForRestoreQuery,
        GetCheckoutResultQuery,
        GetSalesOrderQuery,
        GetSalesOrderPaymentSummaryQuery,
        GetSalesReceiptQuery,
        ListSalesOrdersQuery,
        SearchSalesOrdersQuery,
        GetSalesOrderDetailQuery,
        GetSalesOrderSettlementQuery,
        GetSalesOrderPaymentTransactionsQuery,
        GetSalesOrderTimelineQuery,
        GetSalesOrderReturnSummaryQuery,
        GetAvailablePostSaleActionsQuery,
        PrecheckSalesOrderCancellationQuery,
        GetReturnExchangeOrdersBySalesOrderQuery,
        GetSalesOrderCancellationQuery,
        PrecheckReturnExchangeQuery,
        GetReturnableOrderLinesQuery,
        EvaluateReturnPricingImpactQuery,
      ];

      expect(queryTypes, hasLength(22));
    });

    test('keeps provider-owned capabilities outside the Sales catalog', () {
      const providerOwnedSymbols = <String>[
        'SearchPartnersQuery',
        'CreatePartnerCommand',
        'SearchSellableProductsQuery',
        'SaveRememberedPriceFromOrderCommand',
        'ApplyReceivableCollectionCommand',
      ];

      expect(providerOwnedSymbols, hasLength(5));
      expect(
        SalesPermissions.values,
        isNot(contains('sales.refund.record')),
      );
    });

    test('classifies all 209 fake scenarios into a result/error family', () {
      final definitions = SalesFakeScenarioRegistry.ids
          .map(SalesFakeScenarioRegistry.definitionFor)
          .toList(growable: false);

      expect(definitions, hasLength(209));
      expect(
        definitions.every((definition) => definition.resultFamily.isNotEmpty),
        isTrue,
      );
      expect(
        definitions.map((definition) => definition.outcomeFamily).toSet(),
        containsAll(<SalesFakeOutcomeFamily>{
          SalesFakeOutcomeFamily.success,
          SalesFakeOutcomeFamily.blocked,
          SalesFakeOutcomeFamily.permissionDenied,
          SalesFakeOutcomeFamily.staleVersion,
          SalesFakeOutcomeFamily.idempotencyConflict,
          SalesFakeOutcomeFamily.dependencyUnavailable,
          SalesFakeOutcomeFamily.notFound,
          SalesFakeOutcomeFamily.projectionPending,
          SalesFakeOutcomeFamily.uncertainResult,
        }),
      );
    });

    test('rejects unknown fake scenario IDs', () {
      expect(
        () => FakeSalesModule(scenarioId: 'e99_u99_scn99_unknown'),
        throwsArgumentError,
      );
      expect(
        () => SalesFakeScenarioRegistry.definitionFor(
          'e99_u99_scn99_unknown',
        ),
        throwsArgumentError,
      );
    });

    test('returns a typed fixture for a supported success scenario', () async {
      final module = FakeSalesModule(
        scenarioId: 'e01_u06_scn01_luu_draft_thanh_cong',
      );
      final command = SaveSalesOrderDraftCommand(
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: const <SalesOrderDraftLineInput>[],
        idempotencyKey: 'draft-1',
      );

      final result = await module.executeCommandAsync(command);

      expect(result, isA<SalesOrderDraftDto>());
      expect(result.status, SalesDraftStatus.active);
    });

    test('provides the S01 runtime working-state fixture without CQRS', () {
      final module = FakeSalesModule(
        scenarioId: 'e01_u01_scn01_khoi_tao_don_moi_voi_khach_le',
      );

      expect(module.scenarioFixture, isA<SalesOrderWorkingStateDto>());
    });

    test('provides typed Group C checkout input and precheck fixtures', () {
      expect(
        FakeSalesModule(
          scenarioId: 'e02_u01_scn01_don_chua_co_payment_intent',
        ).scenarioFixture,
        isA<CheckoutMonetarySummaryDto>(),
      );
      expect(
        FakeSalesModule(
          scenarioId: 'e02_u02_scn01_thanh_toan_toan_bo_bang_tien_mat',
        ).scenarioFixture,
        isA<PaymentIntentSummaryDto>(),
      );
      expect(
        FakeSalesModule(
          scenarioId: 'e02_u03_scn01_khach_hang_thanh_toan_mot_phan',
        ).scenarioFixture,
        isA<ReceivableRequirementDto>(),
      );
      expect(
        FakeSalesModule(
          scenarioId: 'e02_u04_scn01_precheck_san_sang',
        ).scenarioFixture,
        isA<CheckoutPrecheckDto>(),
      );
    });

    test('has a correctly typed fixture for every public request', () {
      final requestTypes = SalesFakeContractFixtureFactory.supportedRequestTypes.toList();

      expect(requestTypes, hasLength(41));
      for (final requestType in requestTypes) {
        expect(
          SalesFakeContractFixtureFactory.create(
            requestType,
          ).runtimeType.toString(),
          SalesFakeContractFixtureFactory.resultContractFor(requestType),
          reason: requestType,
        );
      }
    });

    test('uses the S13 order result contract for the sales order read', () {
      expect(
        SalesFakeContractFixtureFactory.resultContractFor('GetSalesOrderQuery'),
        'SalesOrderResultDto',
      );
      expect(
        SalesFakeContractFixtureFactory.create('GetSalesOrderQuery'),
        isA<SalesOrderResultDto>(),
      );
    });

    test('returns the registered error family for a supported request', () {
      final module = FakeSalesModule(
        scenarioId: 'e03_u01_scn07_khong_co_quyen',
      );

      expect(
        () => module.executeQueryAsync(ListSalesOrdersQuery()),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'PERMISSION_DENIED',
          ),
        ),
      );
    });

    test('uses UUID v4 commands and UUID v7 queries', () {
      final command = SaveSalesOrderDraftCommand(
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: const <SalesOrderDraftLineInput>[],
        idempotencyKey: 'draft-1',
      );
      final query = GetSalesOrderQuery(salesOrderId: 'order-1');

      expect(command.id[14], '4');
      expect(query.id[14], '7');
    });
  });
}
