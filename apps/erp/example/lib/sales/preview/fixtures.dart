import 'package:vet45_sales_application/application.dart' as app;
import 'package:erp/features/sales/presentation.dart';

/// Static VMs / DTOs for the Sales presentation example catalog.
abstract final class SalesPreviewFixtures {
  static const _vnd = 'VND';

  static app.MoneyDto vnd(int minor) =>
      app.MoneyDto(amountMinor: minor, currencyCode: _vnd);

  static final updatedAt = DateTime(2026, 8, 18, 14, 32);
  static final completedAt = DateTime(2026, 8, 12, 10, 15);

  static SalesDraftListItemVm get draftComposing => SalesDraftListItemVm(
    draftId: 'draft-1',
    version: 3,
    updatedAt: updatedAt,
    customerLabel: 'Nguyễn Văn An',
    lineCount: 3,
    total: vnd(1250000),
    uiStatus: SalesDraftUiStatus.composing,
    phone: '0903000111',
    note: 'Giao trước 16:00',
    createdByName: 'Minh Anh',
  );

  static SalesDraftListItemVm get draftNeedsCheck => SalesDraftListItemVm(
    draftId: 'draft-2',
    version: 1,
    updatedAt: updatedAt.subtract(const Duration(hours: 2)),
    customerLabel: 'Khách lẻ',
    lineCount: 1,
    total: vnd(90000),
    uiStatus: SalesDraftUiStatus.needsCheck,
    warningMessage: 'Giá sản phẩm đã thay đổi',
    isOwnedByMe: false,
    createdByName: 'Thu Ngân',
  );

  static List<SalesDraftListItemVm> get drafts => [
    draftComposing,
    draftNeedsCheck,
  ];

  static SalesComposeCustomerVm get walkInCustomer =>
      SalesComposeCustomerVm.walkIn();

  static const namedCustomer = SalesComposeCustomerVm(
    displayName: 'Trần Thu',
    phone: '0903000111',
    partnerId: 'partner-1',
  );

  static SalesComposeLineVm get composeLine => SalesComposeLineVm.composed(
    identity: ComposeLineIdentity(
      lineId: 'line-1',
      productId: 'product-1',
      productUnitId: 'unit-1',
      productName: 'Vaccine A',
      unitLabel: 'Lọ',
      catalogUnitPrice: vnd(1250000),
    ),
    input: const ComposeLineUserInput(quantity: 2),
    pricing: ComposeLinePricingNotReady(
      provisionalAppliedUnitPrice: vnd(1250000),
      provisionalListUnitPrice: vnd(1250000),
      provisionalFloorUnitPrice: vnd(1100000),
    ),
    stock: const ComposeLineStockHint(availableQuantity: 8),
  );

  static SalesComposeLineVm get composeLineLowStock =>
      SalesComposeLineVm.composed(
        identity: ComposeLineIdentity(
          lineId: 'line-2',
          productId: 'product-2',
          productUnitId: 'unit-2',
          productName: 'Khoáng chất B',
          unitLabel: 'Hộp',
          catalogUnitPrice: vnd(75000),
        ),
        input: const ComposeLineUserInput(quantity: 1),
        pricing: ComposeLinePricingNotReady(
          provisionalAppliedUnitPrice: vnd(75000),
          provisionalListUnitPrice: vnd(75000),
        ),
        stock: const ComposeLineStockHint(availableQuantity: 2),
      );

  static List<SalesComposeLineVm> get composeLines => [
    composeLine,
    composeLineLowStock,
  ];

  static SalesProductUnitVm get defaultUnit => SalesProductUnitVm(
    productUnitId: 'unit-1',
    unitCode: 'VIAL',
    unitName: 'Lọ',
    unitPrice: vnd(1250000),
    isDefault: true,
    stockQuantity: 12,
    listUnitPrice: vnd(1250000),
    floorUnitPrice: vnd(1100000),
  );

  static SalesProductUnitVm get boxUnit => SalesProductUnitVm(
    productUnitId: 'unit-box',
    unitCode: 'BOX',
    unitName: 'Hộp',
    unitPrice: vnd(24000000),
    stockQuantity: 4,
  );

  static SalesSellableProductVm get product => SalesSellableProductVm(
    productId: 'product-1',
    sku: 'SKU-001',
    displayName: 'Vaccine A',
    units: [defaultUnit, boxUnit],
    barcode: '893000000001',
    stockQuantity: 12,
    packLabel: 'Hộp 20 lọ',
  );

  static SalesSellableProductVm get productBlocked => SalesSellableProductVm(
    productId: 'product-blocked',
    sku: 'SKU-BLK',
    displayName: 'Sản phẩm tạm khóa',
    units: [defaultUnit],
    isBlocked: true,
    blockReason: 'Ngừng bán tại cửa hàng',
  );

  static List<SalesSellableProductVm> get products => [product, productBlocked];

  static const customerItem = SalesCustomerListItemVm(
    partnerId: 'partner-1',
    displayName: 'Trần Thu',
    phone: '0903000111',
    subtitle: 'Khách quen',
  );

  static const customerBlocked = SalesCustomerListItemVm(
    partnerId: 'partner-blocked',
    displayName: 'Khách bị khóa',
    phone: '0903000999',
    isBlocked: true,
  );

  static List<SalesCustomerListItemVm> get customers => [
    customerItem,
    customerBlocked,
  ];

  static const checkoutNamed = SalesCheckoutVm(
    runtimeDraftId: 'draft-1',
    provisionalTotalAmountMinor: 1250000,
    customerName: 'Trần Thu',
    customerPhone: '0903000111',
    customerDebtMinor: 200000,
    paymentMode: SalesPaymentMode.cash,
    cashPaidMinor: 1000000,
    dueDate: null,
  );

  static const checkoutWalkIn = SalesCheckoutVm(
    runtimeDraftId: 'draft-walkin',
    provisionalTotalAmountMinor: 90000,
    isWalkIn: true,
    paymentMode: SalesPaymentMode.bankTransfer,
    bankPaidMinor: 90000,
  );

  static SalesOrderListItemVm get orderCompleted => SalesOrderListItemVm(
    salesOrderId: 'so-1',
    orderNumber: 'DH-000129',
    sourceVersion: 4,
    completedAt: completedAt,
    customerLabel: 'Nguyễn Văn An',
    customerPhone: '0903000111',
    storeLabel: 'Chi nhánh Quận 1',
    total: vnd(1250000),
    lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
    lockStatus: app.SalesOrderLockStatus.unlocked,
    settlementStatus: app.SalesSettlementStatus.paid,
  );

  static SalesOrderListItemVm get orderPartial => SalesOrderListItemVm(
    salesOrderId: 'so-2',
    orderNumber: 'DH-000130',
    sourceVersion: 2,
    completedAt: completedAt,
    customerLabel: 'Lê Gia',
    customerPhone: '0903000222',
    storeLabel: 'Chi nhánh Đà Nẵng',
    total: vnd(1500000),
    lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
    lockStatus: app.SalesOrderLockStatus.unlocked,
    settlementStatus: app.SalesSettlementStatus.partiallyPaid,
  );

  static List<SalesOrderListItemVm> get orders => [
    orderCompleted,
    orderPartial,
  ];

  static const orderDetailItem = SalesOrderDetailItemVm(
    lineId: 'line-1',
    productName: 'Vaccine A',
    unitName: 'Lọ',
    quantity: 1,
    unitPriceMinor: 1250000,
    totalAmountMinor: 1250000,
  );

  static const timelineEntry = SalesOrderDetailTimelineVm(
    title: 'Hoàn tất đơn',
    timestamp: '12/08/2026 10:15',
    actorName: 'Minh Anh',
  );

  static const returnSlip = SalesReturnExchangeSlipItemVm(
    returnExchangeId: 're-1',
    slipNumber: 'PDT-001',
    typeText: 'Đổi hàng',
    dateFormatted: '14/08/2026',
    statusText: 'Hoàn tất',
    diffText: 'Khách trả thêm',
  );

  static const orderDetail = SalesOrderDetailVm(
    orderId: 'so-1',
    orderNumber: 'DH-000129',
    orderVersion: 1,
    createdAtFormatted: '12/08/2026 10:15',
    customerName: 'Nguyễn Văn An',
    customerPhone: '0903000111',
    storeName: 'Chi nhánh Quận 1',
    sellerName: 'Minh Anh',
    totalAmountMinor: 1250000,
    paidAmountMinor: 1250000,
    lifecycleStatus: SalesOrderLifecycleStatus.committed,
    settlementStatus: SalesSettlementStatus.fullyPaid,
    eInvoiceStatus: SalesEInvoiceStatus.notIssued,
    items: [orderDetailItem],
    timeline: [timelineEntry],
    returnExchangeSlips: [returnSlip],
    note: 'Giao trước 16:00',
  );

  static const orderDetailCancelled = SalesOrderDetailVm(
    orderId: 'so-cancel',
    orderNumber: 'DH-000099',
    orderVersion: 1,
    createdAtFormatted: '10/08/2026 09:00',
    customerName: 'Lê Gia',
    customerPhone: '0903000222',
    storeName: 'Chi nhánh Đà Nẵng',
    totalAmountMinor: 500000,
    paidAmountMinor: 0,
    lifecycleStatus: SalesOrderLifecycleStatus.cancelled,
    settlementStatus: SalesSettlementStatus.unpaid,
    eInvoiceStatus: SalesEInvoiceStatus.cancelled,
    items: [orderDetailItem],
    timeline: [timelineEntry],
    cancelReason: 'Khách đổi ý',
    cancelledBy: 'Minh Anh',
    cancelledAtFormatted: '10/08/2026 09:20',
  );

  static const paymentLoaded = SalesOrderPaymentVm(
    orderTotalMinor: 1250000,
    paidTotalMinor: 1000000,
    outstandingMinor: 250000,
    paidCashAmountMinor: 400000,
    paidBankAmountMinor: 600000,
    dueDateFormatted: '30/08/2026',
    settlementStatus: SalesSettlementStatus.partiallyPaid,
    transactions: [],
    hasMoreTransactions: false,
  );

  static const cancellation = SalesOrderCancellationVm(
    cancellationId: 'cancel-1',
    reason: 'Khách đổi ý',
    statusLabel: 'Đã hủy',
    isProcessing: false,
    cancelledByActorId: 'actor-1',
    cancelledByActorName: 'Minh Anh',
    cancelledAtFormatted: '10/08/2026 09:20',
    netConfirmedCollectionFormatted: '0đ',
  );

  static const history = SalesOrderHistoryVm(
    timeline: [timelineEntry],
    returns: [returnSlip],
  );

  static const settlementRefund = SalesReturnExchangeSettlementVm(
    returnExchangeId: 'return-1',
    currencyCode: _vnd,
    netDifferenceMinor: -400000,
    storeRefundMinor: 400000,
    customerCollectMinor: 0,
    receivableCreateMinor: 0,
    receivableReverseMinor: 150000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  static SalesReturnExchangeDetailVm returnDetail() {
    return SalesReturnExchangeDetailVm(
      returnExchangeId: 'return-1',
      salesOrderId: 'so-1',
      referenceNumber: 'PDT-001',
      status: app.ReturnExchangeStatus.confirmed,
      version: 2,
      lines: const [
        app.ReturnExchangeDetailLineDto(
          lineId: 'line-1',
          kind: app.ReturnExchangeLineKind.returnLine,
          product: app.ProductSnapshotDto(
            productId: 'p1',
            sku: 'SKU-1',
            displayName: 'Sản phẩm trả',
          ),
          unit: app.ProductUnitSnapshotDto(
            productUnitId: 'u1',
            unitCode: 'BOX',
            unitName: 'Hộp',
          ),
          quantity: app.QuantityDto(quantityMicros: app.QuantityDto.scale),
          unitPrice: app.MoneyDto(amountMinor: 100000, currencyCode: _vnd),
          lineTotal: app.MoneyDto(amountMinor: 100000, currencyCode: _vnd),
          originalSalesOrderLineId: 'sol-1',
          reasonCode: 'DAMAGED',
          conditionCode: 'OPENED',
        ),
      ],
      valuation: const app.ReturnExchangeValuationDto(
        returnValue: app.MoneyDto(amountMinor: 100000, currencyCode: _vnd),
        exchangeValue: app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
        settlementDifference: app.MoneyDto(
          amountMinor: -100000,
          currencyCode: _vnd,
        ),
        settlementPlan: app.ReturnExchangeSettlementPlanDto(
          currencyCode: _vnd,
          netDifferenceMinor: -100000,
          collectAmountMinor: 0,
          refundAmountMinor: 100000,
          receivableCreateAmountMinor: 0,
          receivableReverseAmountMinor: 0,
          processedCollectMinor: 0,
          processedRefundMinor: 0,
          pendingReceivableCreateMinor: 0,
          pendingReceivableReverseMinor: 0,
          remainderCollectMinor: 0,
          remainderRefundMinor: 100000,
          sourceOrderVersion: 7,
          sourceSettlementVersion: 3,
        ),
        sourceOrderVersion: 7,
      ),
      settlementPlan: const app.ReturnExchangeSettlementPlanDto(
        currencyCode: _vnd,
        netDifferenceMinor: -100000,
        collectAmountMinor: 0,
        refundAmountMinor: 100000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 100000,
        sourceOrderVersion: 7,
        sourceSettlementVersion: 3,
      ),
      completionReady: true,
      createdAt: DateTime.utc(2026, 8, 14, 9),
    );
  }

  static app.SalesReceiptDto receiptFilled() => app.SalesReceiptDto(
    receiptId: 'receipt-filled',
    salesOrderId: 'order-filled',
    version: 1,
    status: app.SalesReceiptStatus.generated,
    generatedAt: DateTime.utc(2026, 8, 12, 2, 41),
    document: app.SalesReceiptDocumentDto(
      receiptNumber: 'PBH-20260812-0101',
      orderNumber: 'SO-0101',
      soldAt: DateTime.utc(2026, 8, 12, 2, 41),
      store: const app.StoreSnapshotDto(
        storeId: 'store-1',
        storeCode: 'HCM-01',
        displayName: 'Chi nhánh Quận 1',
      ),
      seller: const app.ActorSnapshotDto(
        actorId: 'seller-1',
        displayName: 'Minh Anh',
      ),
      customer: const app.CustomerSnapshotDto(
        customerId: 'customer-1',
        displayName: 'Trần Thu',
        phoneNumber: '0903000111',
      ),
      lines: const <app.SalesReceiptLineDto>[
        app.SalesReceiptLineDto(
          lineId: 'line-1',
          product: app.ProductSnapshotDto(
            productId: 'product-1',
            sku: 'SKU-001',
            displayName: 'Vaccine A',
          ),
          unit: app.ProductUnitSnapshotDto(
            productUnitId: 'unit-1',
            unitCode: 'VIAL',
            unitName: 'Lọ',
          ),
          quantity: app.QuantityDto(quantityMicros: app.QuantityDto.scale),
          unitPrice: app.MoneyDto(amountMinor: 100000, currencyCode: _vnd),
          discountTotal: app.MoneyDto(amountMinor: 10000, currencyCode: _vnd),
          lineTotal: app.MoneyDto(amountMinor: 90000, currencyCode: _vnd),
        ),
      ],
      subtotal: const app.MoneyDto(amountMinor: 100000, currencyCode: _vnd),
      discountTotal: const app.MoneyDto(amountMinor: 10000, currencyCode: _vnd),
      orderTotal: const app.MoneyDto(amountMinor: 90000, currencyCode: _vnd),
      paidTotal: const app.MoneyDto(amountMinor: 90000, currencyCode: _vnd),
      outstandingTotal: const app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
      payments: const <app.PaymentIntentSummaryDto>[
        app.PaymentIntentSummaryDto(
          method: app.SalesPaymentMethod.cash,
          amount: app.MoneyDto(amountMinor: 90000, currencyCode: _vnd),
          status: app.SalesPaymentStatus.confirmed,
        ),
      ],
    ),
  );

  static app.SalesReceiptDto receiptPartiallyPaid() => app.SalesReceiptDto(
    receiptId: 'receipt-partial',
    salesOrderId: 'order-partial',
    version: 2,
    status: app.SalesReceiptStatus.generated,
    generatedAt: DateTime.utc(2026, 8, 12, 3, 15),
    document: app.SalesReceiptDocumentDto(
      receiptNumber: 'PBH-20260812-0202',
      orderNumber: 'SO-0202',
      soldAt: DateTime.utc(2026, 8, 12, 3, 15),
      store: const app.StoreSnapshotDto(
        storeId: 'store-2',
        storeCode: 'DN-02',
        displayName: 'Chi nhánh Đà Nẵng',
      ),
      seller: const app.ActorSnapshotDto(
        actorId: 'seller-2',
        displayName: 'Phương Hà',
      ),
      customer: const app.CustomerSnapshotDto(
        customerId: 'customer-2',
        displayName: 'Lê Gia',
      ),
      lines: const <app.SalesReceiptLineDto>[
        app.SalesReceiptLineDto(
          lineId: 'line-2',
          product: app.ProductSnapshotDto(
            productId: 'product-2',
            sku: 'SKU-002',
            displayName: 'Khoáng chất B',
          ),
          unit: app.ProductUnitSnapshotDto(
            productUnitId: 'unit-2',
            unitCode: 'BOX',
            unitName: 'Hộp',
          ),
          quantity: app.QuantityDto(quantityMicros: 2 * app.QuantityDto.scale),
          unitPrice: app.MoneyDto(amountMinor: 75000, currencyCode: _vnd),
          discountTotal: app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
          lineTotal: app.MoneyDto(amountMinor: 150000, currencyCode: _vnd),
        ),
      ],
      subtotal: const app.MoneyDto(amountMinor: 150000, currencyCode: _vnd),
      discountTotal: const app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
      orderTotal: const app.MoneyDto(amountMinor: 150000, currencyCode: _vnd),
      paidTotal: const app.MoneyDto(amountMinor: 50000, currencyCode: _vnd),
      outstandingTotal: const app.MoneyDto(
        amountMinor: 100000,
        currencyCode: _vnd,
      ),
      payments: const <app.PaymentIntentSummaryDto>[
        app.PaymentIntentSummaryDto(
          method: app.SalesPaymentMethod.manualBankTransfer,
          amount: app.MoneyDto(amountMinor: 50000, currencyCode: _vnd),
          status: app.SalesPaymentStatus.confirmed,
        ),
      ],
      dueAt: DateTime.utc(2026, 8, 30),
    ),
  );

  static app.SalesReceiptDto receiptMinimal() => app.SalesReceiptDto(
    receiptId: 'receipt-min',
    salesOrderId: 'order-min',
    version: 1,
    status: app.SalesReceiptStatus.generated,
    generatedAt: DateTime.utc(2026, 8, 12, 5, 5),
    document: app.SalesReceiptDocumentDto(
      receiptNumber: 'PBH-20260812-0303',
      orderNumber: 'SO-0303',
      soldAt: DateTime.utc(2026, 8, 12, 5, 5),
      store: const app.StoreSnapshotDto(
        storeId: 'store-3',
        storeCode: 'KTT',
        displayName: 'Kho trung tâm',
      ),
      seller: const app.ActorSnapshotDto(
        actorId: 'seller-3',
        displayName: 'Thu Ngân',
      ),
      lines: const <app.SalesReceiptLineDto>[
        app.SalesReceiptLineDto(
          lineId: 'line-3',
          product: app.ProductSnapshotDto(
            productId: 'product-3',
            sku: 'SKU-MTH-C',
            displayName: 'Men tiêu hóa C',
          ),
          unit: app.ProductUnitSnapshotDto(
            productUnitId: 'unit-3',
            unitCode: 'GOI',
            unitName: 'Gói',
          ),
          quantity: app.QuantityDto(quantityMicros: app.QuantityDto.scale),
          unitPrice: app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
          discountTotal: app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
          lineTotal: app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
        ),
      ],
      subtotal: const app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
      discountTotal: const app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
      orderTotal: const app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
      paidTotal: const app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
      outstandingTotal: const app.MoneyDto(amountMinor: 0, currencyCode: _vnd),
      payments: const <app.PaymentIntentSummaryDto>[
        app.PaymentIntentSummaryDto(
          method: app.SalesPaymentMethod.cash,
          amount: app.MoneyDto(amountMinor: 30000, currencyCode: _vnd),
          status: app.SalesPaymentStatus.confirmed,
        ),
      ],
    ),
  );
}
