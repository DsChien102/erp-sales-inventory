import 'package:vet45_sales_application/application.dart';

import 'sales_fake_data.dart';
import 'sales_fake_scenario_definition.dart';

/// Typed, deterministic fixtures for every Sales-owned public CQRS request.
abstract final class SalesFakeContractFixtureFactory {
  static Iterable<String> get supportedRequestTypes => _resultFamilyByRequest.keys;

  static bool supports(String requestType) => _resultFamilyByRequest.containsKey(requestType);

  static String resultContractFor(String requestType) {
    final family = _resultFamilyByRequest[requestType];
    if (family == null) {
      throw UnsupportedError('Unknown Sales contract request $requestType');
    }
    return _resultContractByFamily[family] ??
        (throw StateError('Missing result contract for $family'));
  }

  static Object createScenarioFixture(
    SalesFakeScenarioDefinition definition,
  ) {
    return switch (definition.resultFamily) {
      'SalesOrderWorkingStateDto' => SalesOrderWorkingStateDto(
        store: _store,
        customer: _customer,
        currencyCode: 'VND',
        lines: const <CheckoutLineInput>[],
      ),
      'CustomerSelectionDto' => const CustomerSelectionDto(
        customer: _customer,
        isWalkIn: false,
      ),
      'DraftLinePreviewDto' => const DraftLinePreviewDto(
        product: _product,
        unit: _unit,
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: _total,
        lineTotal: _total,
      ),
      'PricingPreviewDto' => create('PreviewSalesPricingQuery'),
      'CheckoutMonetarySummaryDto' => _monetarySummary,
      'PaymentIntentSummaryDto' => const PaymentIntentSummaryDto(
        method: SalesPaymentMethod.cash,
        amount: _total,
        status: SalesPaymentStatus.confirmed,
      ),
      'ReceivableRequirementDto' => const ReceivableRequirementDto(
        isRequired: true,
        amount: _total,
        customerId: _customerId,
      ),
      'CheckoutPrecheckDto' => create('PrecheckSalesOrderCheckoutQuery'),
      'CheckoutResultViewDto' => CheckoutResultViewDto(
        checkout: const CheckoutResultDto(
          idempotencyKey: 'fake-checkout-attempt',
          salesOrderId: 'order-1',
          salesOrderVersion: 3,
          status: CheckoutResultStatus.succeeded,
        ),
        order: _orderResult,
        payment: _paymentSummary,
      ),
      _ => _createByResultContract(definition),
    };
  }

  static Object _createByResultContract(
    SalesFakeScenarioDefinition definition,
  ) {
    for (final entry in _resultFamilyByRequest.entries) {
      if (_resultContractByFamily[entry.value] == definition.resultFamily) {
        return create(entry.key);
      }
    }
    // Provider-owned result families remain metadata, not copied Sales types.
    return definition;
  }

  static Object create(String requestType) {
    final family = _resultFamilyByRequest[requestType];
    if (family == null) {
      throw UnsupportedError('Unknown Sales contract request $requestType');
    }
    return switch (family) {
      'draft' => _draft(),
      'draftPage' => PagedSalesOrderDraftListDto(
        page: OpaqueCursorPageDto<SalesOrderDraftDto>(
          items: <SalesOrderDraftDto>[_draft()],
          hasMore: false,
        ),
      ),
      'draftRestore' => SalesOrderDraftForRestoreDto(
        draft: _draft(),
        savedAt: _now,
        savedByActorId: _actor.actorId,
      ),
      'pricingPreview' => PricingPreviewDto(
        lines: <DraftLinePreviewDto>[],
        summary: _monetarySummary,
        blockers: <SalesBlockerDto>[],
      ),
      'checkoutPrecheck' => CheckoutPrecheckDto(
        canFinalize: true,
        blockers: <SalesBlockerDto>[],
        monetarySummary: _monetarySummary,
        receivableRequirement: const ReceivableRequirementDto(
          isRequired: false,
          amount: _zero,
        ),
      ),
      'checkoutResult' => const CheckoutResultDto(
        idempotencyKey: 'fake-checkout-attempt',
        salesOrderId: 'fake-sales-order',
        salesOrderVersion: 1,
        status: CheckoutResultStatus.succeeded,
      ),
      'orderResult' => _orderResult,
      'paymentSummary' => _paymentSummary,
      'settlement' => const SalesOrderSettlementDto(
        settlementId: 'fake-settlement',
        salesOrderId: 'fake-sales-order',
        version: 1,
        status: SalesSettlementStatus.paid,
        orderTotal: _total,
        paidTotal: _total,
        refundedTotal: _zero,
        outstanding: _zero,
      ),
      'receipt' => _receipt,
      'orderPage' => PagedSalesOrderListDto(
        page: OpaqueCursorPageDto<SalesOrderListItemDto>(
          items: SalesFakeData.seedOrderListItems(),
          hasMore: false,
        ),
      ),
      'orderDetail' => SalesOrderDetailDto(
        order: _order,
        committedAt: _now,
        store: _store,
        seller: _actor,
        customer: _customer,
        lines: <SalesOrderLineDto>[_line],
      ),
      'paymentTransactions' => SalesPaymentTransactionsDto(
        page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
          items: <SalesPaymentTransactionDto>[
            SalesPaymentTransactionDto(
              transactionId: 'fake-payment',
              method: SalesPaymentMethod.cash,
              amount: _total,
              status: SalesPaymentStatus.confirmed,
              recordedAt: _now,
            ),
          ],
          hasMore: false,
        ),
      ),
      'timeline' => SalesOrderTimelineDto(
        salesOrderId: 'fake-sales-order',
        entries: <SalesOrderTimelineEntryDto>[
          SalesOrderTimelineEntryDto(
            eventId: 'fake-event',
            eventType: 'sales_order_confirmed',
            occurredAt: _now,
            sourceVersion: 1,
            actor: _actor,
            description: 'Đơn đã xác nhận',
            amount: _total,
          ),
        ],
      ),
      'returnSummary' => SalesOrderReturnSummaryDto(
        salesOrderId: 'fake-sales-order',
        returns: const <ReturnExchangeSummaryDto>[],
      ),
      'postSaleActions' => const AvailablePostSaleActionsDto(
        canCancel: true,
        canReturnExchange: true,
      ),
      'cancellationPrecheck' => CancellationPrecheckDto(
        allowed: true,
        sourceVersion: 1,
        sourceSettlementVersion: 1,
        blockers: <SalesBlockerDto>[],
      ),
      'cancellationResult' => const SalesOrderCancellationResultDto(
        cancellationId: 'fake-cancellation',
        salesOrderId: 'fake-sales-order',
        salesOrderVersion: 2,
        status: SalesOrderCancellationStatus.confirmed,
      ),
      'cancellationDetail' => SalesOrderCancellationDetailDto(
        result: const SalesOrderCancellationResultDto(
          cancellationId: 'fake-cancellation',
          salesOrderId: 'fake-sales-order',
          salesOrderVersion: 2,
          status: SalesOrderCancellationStatus.confirmed,
        ),
        reason: const CancellationReasonDto(
          reasonText: 'Customer request',
        ),
        cancelledAt: _now,
        cancelledByActorId: 'fake-actor',
        netConfirmedCollectionMinor: 0,
      ),
      'returnPrecheck' => ReturnExchangePrecheckDto(
        allowed: true,
        sourceVersion: 1,
        blockers: <SalesBlockerDto>[],
      ),
      'returnableLines' => ReturnableOrderLinesDto(
        salesOrderId: 'fake-sales-order',
        sourceVersion: 1,
        lines: const <ReturnableOrderLineDto>[
          ReturnableOrderLineDto(
            salesOrderLineId: 'line_1',
            product: ProductSnapshotDto(
              productId: 'product-1',
              sku: 'SKU-1',
              displayName: 'Sản phẩm trả mẫu',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'unit-1',
              unitCode: 'BOX',
              unitName: 'Hộp',
            ),
            soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
            returnableQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
            originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
          ),
        ],
      ),
      'returnFormPolicy' => ReturnExchangeFormPolicyDto(
        reasons: const <ReturnExchangePolicyOptionDto>[
          ReturnExchangePolicyOptionDto(
            code: 'DAMAGED',
            displayName: 'Hỏng',
            sortOrder: 100,
          ),
          ReturnExchangePolicyOptionDto(
            code: 'WRONG_ITEM',
            displayName: 'Sai hàng',
            sortOrder: 200,
          ),
        ],
        conditions: const <ReturnExchangePolicyOptionDto>[
          ReturnExchangePolicyOptionDto(
            code: 'OPENED',
            displayName: 'Đã mở',
            sortOrder: 100,
          ),
          ReturnExchangePolicyOptionDto(
            code: 'SEALED',
            displayName: 'Nguyên seal',
            sortOrder: 200,
          ),
        ],
      ),
      'returnDetail' => ReturnExchangeDetailDto(
        result: const ReturnExchangeResultDto(
          returnExchangeId: 'fake-return-exchange',
          salesOrderId: 'fake-sales-order',
          version: 2,
          status: ReturnExchangeStatus.draft,
        ),
        referenceNumber: 'RE-FAKE-001',
        entrySource: ReturnExchangeEntrySource.standard,
        createdAt: _now,
        confirmedByActorId: null,
        confirmedAt: null,
        completedAt: null,
        lines: const <ReturnExchangeDetailLineDto>[],
        valuation: const ReturnExchangeValuationDto(
          returnValue: _total,
          exchangeValue: _total,
          settlementDifference: _zero,
          settlementPlan: ReturnExchangeSettlementPlanDto(
            currencyCode: 'VND',
            netDifferenceMinor: 0,
            collectAmountMinor: 0,
            refundAmountMinor: 0,
            receivableCreateAmountMinor: 0,
            receivableReverseAmountMinor: 0,
            processedCollectMinor: 0,
            processedRefundMinor: 0,
            pendingReceivableCreateMinor: 0,
            pendingReceivableReverseMinor: 0,
            remainderCollectMinor: 0,
            remainderRefundMinor: 0,
            sourceOrderVersion: 1,
            sourceSettlementVersion: 1,
          ),
          sourceOrderVersion: 1,
        ),
        settlementPlan: const ReturnExchangeSettlementPlanDto(
          currencyCode: 'VND',
          netDifferenceMinor: 0,
          collectAmountMinor: 0,
          refundAmountMinor: 0,
          receivableCreateAmountMinor: 0,
          receivableReverseAmountMinor: 0,
          processedCollectMinor: 0,
          processedRefundMinor: 0,
          pendingReceivableCreateMinor: 0,
          pendingReceivableReverseMinor: 0,
          remainderCollectMinor: 0,
          remainderRefundMinor: 0,
          sourceOrderVersion: 1,
          sourceSettlementVersion: 1,
        ),
        completionReady: false,
      ),
      'returnDraft' => ReturnExchangeDraftDto(
        returnExchangeId: 'fake-return-exchange',
        salesOrderId: 'fake-sales-order',
        version: 1,
        status: ReturnExchangeStatus.draft,
        lines: const <ReturnExchangeLineInput>[],
      ),
      'returnValuation' => const ReturnExchangeValuationDto(
        returnValue: _total,
        exchangeValue: _total,
        settlementDifference: _zero,
        settlementPlan: ReturnExchangeSettlementPlanDto(
          currencyCode: 'VND',
          netDifferenceMinor: 0,
          collectAmountMinor: 0,
          refundAmountMinor: 0,
          receivableCreateAmountMinor: 0,
          receivableReverseAmountMinor: 0,
          processedCollectMinor: 0,
          processedRefundMinor: 0,
          pendingReceivableCreateMinor: 0,
          pendingReceivableReverseMinor: 0,
          remainderCollectMinor: 0,
          remainderRefundMinor: 0,
          sourceOrderVersion: 1,
          sourceSettlementVersion: 1,
        ),
        sourceOrderVersion: 1,
      ),
      'returnSettlement' => const ReturnExchangeSettlementResultDto(
        returnExchangeId: 'fake-return-exchange',
        difference: _zero,
        status: SalesSettlementStatus.paid,
      ),
      'returnResult' => const ReturnExchangeResultDto(
        returnExchangeId: 'fake-return-exchange',
        salesOrderId: 'fake-sales-order',
        version: 2,
        status: ReturnExchangeStatus.completed,
      ),
      _ => throw StateError('Missing fixture family $family'),
    };
  }

  static SalesContractException? errorFor(
    SalesFakeScenarioDefinition definition,
  ) {
    final code = switch (definition.outcomeFamily) {
      SalesFakeOutcomeFamily.success => null,
      SalesFakeOutcomeFamily.permissionDenied => 'PERMISSION_DENIED',
      SalesFakeOutcomeFamily.staleVersion => 'STALE_VERSION',
      SalesFakeOutcomeFamily.idempotencyConflict => 'IDEMPOTENCY_CONFLICT',
      SalesFakeOutcomeFamily.dependencyUnavailable => 'DEPENDENCY_UNAVAILABLE',
      SalesFakeOutcomeFamily.notFound => 'NOT_FOUND',
      SalesFakeOutcomeFamily.projectionPending => 'PROJECTION_PENDING',
      SalesFakeOutcomeFamily.uncertainResult => 'UNCERTAIN_RESULT',
      SalesFakeOutcomeFamily.blocked => _blockedCode(definition.id),
    };
    return code == null
        ? null
        : SalesContractException(
            code,
            details: <String, Object?>{
              'scenarioId': definition.id,
              'resultFamily': definition.resultFamily,
            },
          );
  }

  static String _blockedCode(String scenarioId) {
    if (scenarioId.contains('noop_')) return 'NO_OP';
    if (scenarioId.contains('reject_field')) return 'FIELD_NOT_ALLOWED';
    if (scenarioId.startsWith('e02_')) return 'CHECKOUT_BLOCKED';
    if (scenarioId.startsWith('e04_')) return 'ADJUSTMENT_BLOCKED';
    if (scenarioId.startsWith('e05_')) return 'CANCELLATION_BLOCKED';
    if (scenarioId.startsWith('e06_')) return 'RETURN_EXCHANGE_BLOCKED';
    return 'CONTEXT_INVALID';
  }

  static SalesOrderDraftDto _draft() => SalesOrderDraftDto(
    draftId: 'fake-draft',
    version: 1,
    status: SalesDraftStatus.active,
    storeId: _store.storeId,
    customer: _customer,
    orderNote: null,
    savedAt: _now,
    savedByActorId: _actor.actorId,
    pricingPreviewToken: null,
    needsRevalidation: false,
    lines: <SalesOrderDraftLineDto>[_draftLine],
    total: _total,
  );

  static final DateTime _now = DateTime.utc(2026, 7, 28);
  static const MoneyDto _zero = MoneyDto(
    amountMinor: 0,
    currencyCode: 'VND',
  );
  static const MoneyDto _total = MoneyDto(
    amountMinor: 125000,
    currencyCode: 'VND',
  );
  static const ActorSnapshotDto _actor = ActorSnapshotDto(
    actorId: 'fake-actor',
    displayName: 'Fake actor',
  );
  static const CustomerSnapshotDto _customer = CustomerSnapshotDto(
    customerId: 'fake-customer',
    displayName: 'Fake customer',
  );
  static const String _customerId = 'fake-customer';
  static const ProductSnapshotDto _product = ProductSnapshotDto(
    productId: 'fake-product',
    sku: 'FAKE-SKU',
    displayName: 'Fake product',
  );
  static const ProductUnitSnapshotDto _unit = ProductUnitSnapshotDto(
    productUnitId: 'fake-unit',
    unitCode: 'EA',
    unitName: 'Each',
  );
  static const StoreSnapshotDto _store = StoreSnapshotDto(
    storeId: 'fake-store',
    storeCode: 'STORE',
    displayName: 'Fake store',
  );
  static final SalesOrderDraftLineDto _draftLine = SalesOrderDraftLineDto(
    lineId: 'fake-line',
    productId: _product.productId,
    productSku: _product.sku!,
    productName: _product.displayName,
    productUnitId: _unit.productUnitId,
    unitCode: _unit.unitCode!,
    unitName: _unit.unitName,
    quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
    appliedUnitPrice: _total,
    lineTotal: _total,
  );
  static const SalesOrderLineDto _line = SalesOrderLineDto(
    lineId: 'fake-line',
    product: _product,
    unit: _unit,
    quantity: QuantityDto(quantityMicros: QuantityDto.scale),
    unitPrice: _total,
    lineTotal: _total,
  );
  static const SalesOrderDto _order = SalesOrderDto(
    salesOrderId: 'fake-sales-order',
    orderNumber: 'SO-FAKE',
    version: 1,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: _total,
  );
  static final SalesOrderResultDto _orderResult = SalesOrderResultDto(
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
  static final SalesReceiptDocumentDto _receiptDocument = SalesReceiptDocumentDto(
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
  );
  static final SalesReceiptDto _receipt = SalesReceiptDto(
    receiptId: 'receipt-1',
    salesOrderId: 'order-1',
    version: 1,
    status: SalesReceiptStatus.generated,
    generatedAt: DateTime.utc(2026, 8, 12, 2, 41),
    document: _receiptDocument,
  );
  static const CheckoutMonetarySummaryDto _monetarySummary = CheckoutMonetarySummaryDto(
    subtotal: _total,
    discountTotal: _zero,
    grandTotal: _total,
  );
  static const SalesOrderPaymentSummaryDto _paymentSummary = SalesOrderPaymentSummaryDto(
    status: SalesSettlementStatus.paid,
    orderTotal: _total,
    paidTotal: _total,
    outstandingTotal: _zero,
  );

  static const _resultFamilyByRequest = <String, String>{
    'SaveSalesOrderDraftCommand': 'draft',
    'UpdateSalesOrderDraftCommand': 'draft',
    'CancelSalesOrderDraftCommand': 'draft',
    'FinalizeSalesOrderCommand': 'checkoutResult',
    'InitializeSalesOrderSettlementCommand': 'settlement',
    'RecordSalesPaymentCommand': 'paymentSummary',
    'GenerateSalesReceiptCommand': 'receipt',
    'RecordSalesReceiptPrintedCommand': 'receipt',
    'RecordSalesReceiptSharedCommand': 'receipt',
    'ArchiveSalesReceiptCommand': 'receipt',
    'ConfirmSalesOrderCancellationCommand': 'cancellationResult',
    'StartReturnExchangeCommand': 'returnDraft',
    'UpdateReturnExchangeCommand': 'returnDraft',
    'CancelReturnExchangeCommand': 'returnResult',
    'ConfirmReturnExchangeCommand': 'returnResult',
    'CompleteReturnExchangeCommand': 'returnResult',
    'RecordSalesRefundCommand': 'returnSettlement',
    'PreviewSalesPricingQuery': 'pricingPreview',
    'PrecheckSalesOrderCheckoutQuery': 'checkoutPrecheck',
    'ListSalesOrderDraftsQuery': 'draftPage',
    'GetSalesOrderDraftForRestoreQuery': 'draftRestore',
    'GetCheckoutResultQuery': 'checkoutResult',
    'GetSalesOrderQuery': 'orderResult',
    'GetSalesOrderPaymentSummaryQuery': 'paymentSummary',
    'GetSalesReceiptQuery': 'receipt',
    'ListSalesOrdersQuery': 'orderPage',
    'SearchSalesOrdersQuery': 'orderPage',
    'GetSalesOrderDetailQuery': 'orderDetail',
    'GetSalesOrderSettlementQuery': 'settlement',
    'GetSalesOrderPaymentTransactionsQuery': 'paymentTransactions',
    'GetSalesOrderTimelineQuery': 'timeline',
    'GetSalesOrderReturnSummaryQuery': 'returnSummary',
    'GetAvailablePostSaleActionsQuery': 'postSaleActions',
    'PrecheckSalesOrderCancellationQuery': 'cancellationPrecheck',
    'GetReturnExchangeOrdersBySalesOrderQuery': 'returnSummary',
    'GetSalesOrderCancellationQuery': 'cancellationDetail',
    'PrecheckReturnExchangeQuery': 'returnPrecheck',
    'GetReturnableOrderLinesQuery': 'returnableLines',
    'GetReturnExchangeFormPolicyQuery': 'returnFormPolicy',
    'GetReturnExchangeDetailQuery': 'returnDetail',
    'EvaluateReturnPricingImpactQuery': 'returnValuation',
  };

  static const _resultContractByFamily = <String, String>{
    'draft': 'SalesOrderDraftDto',
    'draftPage': 'PagedSalesOrderDraftListDto',
    'draftRestore': 'SalesOrderDraftForRestoreDto',
    'pricingPreview': 'PricingPreviewDto',
    'checkoutPrecheck': 'CheckoutPrecheckDto',
    'checkoutResult': 'CheckoutResultDto',
    'orderResult': 'SalesOrderResultDto',
    'paymentSummary': 'SalesOrderPaymentSummaryDto',
    'settlement': 'SalesOrderSettlementDto',
    'receipt': 'SalesReceiptDto',
    'orderPage': 'PagedSalesOrderListDto',
    'orderDetail': 'SalesOrderDetailDto',
    'paymentTransactions': 'SalesPaymentTransactionsDto',
    'timeline': 'SalesOrderTimelineDto',
    'returnSummary': 'SalesOrderReturnSummaryDto',
    'postSaleActions': 'AvailablePostSaleActionsDto',
    'cancellationPrecheck': 'CancellationPrecheckDto',
    'cancellationResult': 'SalesOrderCancellationResultDto',
    'cancellationDetail': 'SalesOrderCancellationDetailDto',
    'returnPrecheck': 'ReturnExchangePrecheckDto',
    'returnableLines': 'ReturnableOrderLinesDto',
    'returnFormPolicy': 'ReturnExchangeFormPolicyDto',
    'returnDetail': 'ReturnExchangeDetailDto',
    'returnDraft': 'ReturnExchangeDraftDto',
    'returnValuation': 'ReturnExchangeValuationDto',
    'returnSettlement': 'ReturnExchangeSettlementResultDto',
    'returnResult': 'ReturnExchangeResultDto',
  };
}
