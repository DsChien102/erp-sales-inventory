import 'package:vet45_sales_application/application.dart';

/// Single source of truth for all Sales domain fake & seed mock data.
///
/// Used in FE Shell mode and contract tests. When backend RPC gateways
/// are ready, switching DI container registrations to real gateways will
/// replace this mock data seamlessly without changing any UI presentation code.
abstract final class SalesFakeData {
  static final StoreSnapshotDto _defaultStore = const StoreSnapshotDto(
    storeId: 'store-center',
    storeCode: 'STORE-001',
    displayName: 'Cửa hàng Trung tâm',
  );
  static const ActorSnapshotDto _defaultSeller = ActorSnapshotDto(
    actorId: 'actor-1',
    displayName: 'Minh Anh',
  );

  /// Representative list-item DTOs for S15 list/search.
  static List<SalesOrderListItemDto> seedOrderListItems() {
    final DateTime anchor = DateTime.utc(2026, 7, 29, 10, 32);
    return seedOrders()
        .map((dto) {
          final id = dto.salesOrderId;
          final isCancelled =
              dto.lifecycleStatus == SalesOrderLifecycleStatus.cancelled || id == 'so-demo-002';
          final isUnpaid = id == 'so-demo-005' || id == 'so-demo-007';
          final isPartiallyPaid = id == 'so-demo-004' || id == 'so-demo-008';
          final isRefunded = id == 'so-demo-002';

          final settlementStatus = isCancelled || isRefunded
              ? SalesSettlementStatus.refunded
              : (isUnpaid
                    ? SalesSettlementStatus.unpaid
                    : (isPartiallyPaid
                          ? SalesSettlementStatus.partiallyPaid
                          : SalesSettlementStatus.paid));

          return SalesOrderListItemDto(
            salesOrderId: dto.salesOrderId,
            orderNumber: dto.orderNumber,
            sourceVersion: dto.version,
            committedAt: anchor,
            customer: _getCustomerForOrder(dto.salesOrderId),
            store: _defaultStore,
            total: dto.total,
            lifecycleStatus: dto.lifecycleStatus,
            lockStatus: dto.lockStatus,
            settlementStatus: settlementStatus,
            returnStatus: (id == 'so-demo-006' || id == 'so-demo-008')
                ? SalesOrderReturnProjectionStatus.partiallyReturned
                : SalesOrderReturnProjectionStatus.none,
            eInvoiceStatus:
                (id == 'so-demo-001' ||
                    id == 'so-demo-003' ||
                    id == 'so-demo-006' ||
                    id == 'so-demo-008')
                ? IntegrationDeliveryStatus.delivered
                : IntegrationDeliveryStatus.queued,
          );
        })
        .toList(growable: false);
  }

  /// Representative Sales Order DTOs covering all status & settlement combinations.
  static List<SalesOrderDto> seedOrders() {
    return <SalesOrderDto>[
      SalesOrderDto(
        salesOrderId: 'so-demo-001',
        orderNumber: 'DH-000245',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 1245000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-002',
        orderNumber: 'DH-000244',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.cancelled,
        lockStatus: SalesOrderLockStatus.locked,
        total: const MoneyDto(amountMinor: 3580000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-003',
        orderNumber: 'DH-000243',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 245000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-004',
        orderNumber: 'DH-000242',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 890000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-005',
        orderNumber: 'DH-000240',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 2400000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-006',
        orderNumber: 'DH-000238',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 175000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-008',
        orderNumber: 'DH-000239',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 4500000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-009',
        orderNumber: 'DH-000241',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 650000, currencyCode: 'VND'),
      ),
      SalesOrderDto(
        salesOrderId: 'so-demo-007',
        orderNumber: 'DH-000230',
        version: 1,
        lifecycleStatus: SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 980000, currencyCode: 'VND'),
      ),
    ];
  }

  /// Finds or generates a matching SalesOrderDetailDto for any requested orderId.
  static SalesOrderDetailDto findOrderDetail(String salesOrderId) {
    final orders = seedOrders();
    final match = orders.firstWhere(
      (o) => o.salesOrderId == salesOrderId || o.orderNumber == salesOrderId,
      orElse: () => SalesOrderDto(
        salesOrderId: salesOrderId,
        orderNumber: salesOrderId.contains('DH') ? salesOrderId : 'DH-000245',
        version: 1,
        lifecycleStatus: salesOrderId.contains('cancel') || salesOrderId.contains('d06')
            ? SalesOrderLifecycleStatus.cancelled
            : SalesOrderLifecycleStatus.completed,
        lockStatus: SalesOrderLockStatus.unlocked,
        total: const MoneyDto(amountMinor: 1245000, currencyCode: 'VND'),
      ),
    );

    final customer = _getCustomerForOrder(match.salesOrderId);
    final lines = _getLinesForOrder(match.salesOrderId, match.total);

    return SalesOrderDetailDto(
      order: match,
      committedAt: DateTime.utc(2026, 7, 29, 10, 32),
      store: _defaultStore,
      seller: _defaultSeller,
      customer: customer,
      lines: lines,
    );
  }

  /// Returns customer's existing debt for a given orderId (1.200.000đ for the 4 bottom orders).
  static int getExistingDebtForOrder(String orderId) {
    switch (orderId) {
      case 'so-demo-006':
      case 'so-demo-007':
      case 'so-demo-008':
      case 'so-demo-009':
        return 1200000;
      default:
        if (orderId.contains('238') ||
            orderId.contains('239') ||
            orderId.contains('241') ||
            orderId.contains('230')) {
          return 1200000;
        }
        return 0;
    }
  }

  static CustomerSnapshotDto _getCustomerForOrder(String orderId) {
    if (orderId.contains('001') || orderId.contains('004') || orderId.contains('DH-000129')) {
      return const CustomerSnapshotDto(
        customerId: 'cust-001',
        displayName: 'Nguyễn Văn An',
      );
    }
    switch (orderId) {
      case 'so-demo-002':
        return const CustomerSnapshotDto(
          customerId: 'cust-002',
          displayName: 'Công ty Minh Phát',
        );
      case 'so-demo-005':
        return const CustomerSnapshotDto(
          customerId: 'cust-003',
          displayName: 'Đại lý An Bình',
        );
      case 'so-demo-008':
        return const CustomerSnapshotDto(
          customerId: 'cust-004',
          displayName: 'Trịnh Văn Bình',
          existingDebtMinor: 1200000,
        );
      case 'so-demo-009':
        return const CustomerSnapshotDto(
          customerId: 'cust-005',
          displayName: 'Lê Hoàng Nam',
          existingDebtMinor: 500000,
        );
      case 'so-demo-007':
        return const CustomerSnapshotDto(
          customerId: 'cust-006',
          displayName: 'Phạm Thị Hoa',
          existingDebtMinor: 1200000,
        );
      case 'so-demo-006':
        return const CustomerSnapshotDto(
          customerId: 'cust-007',
          displayName: 'Khách lẻ',
          existingDebtMinor: 1200000,
        );
      case 'so-demo-003':
      default:
        return const CustomerSnapshotDto(
          customerId: 'cust-walkin',
          displayName: 'Khách lẻ',
        );
    }
  }

  static List<SalesOrderLineDto> _getLinesForOrder(String orderId, MoneyDto total) {
    switch (orderId) {
      case 'so-demo-001':
        return const [
          SalesOrderLineDto(
            lineId: 'line-001-1',
            product: ProductSnapshotDto(
              productId: 'prod-001',
              sku: 'AD3EC-5L',
              displayName: 'AD3EC 5L (tyx)',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-can',
              unitCode: 'CAN',
              unitName: 'Can',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-001-2',
            product: ProductSnapshotDto(
              productId: 'prod-003',
              sku: 'VITC-100G',
              displayName: 'Vitamin C 100g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-goi',
              unitCode: 'BAG',
              unitName: 'Gói',
            ),
            quantity: QuantityDto(quantityMicros: 5000000),
            unitPrice: MoneyDto(amountMinor: 49000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 245000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-002':
        return const [
          SalesOrderLineDto(
            lineId: 'line-002-1',
            product: ProductSnapshotDto(
              productId: 'prod-002',
              sku: 'AMOX-1KG',
              displayName: 'Amoxicillin 50% 1kg',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-hop',
              unitCode: 'BOX',
              unitName: 'Hộp',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 1790000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 1790000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-002-2',
            product: ProductSnapshotDto(
              productId: 'prod-005',
              sku: 'TYLO-500G',
              displayName: 'Tylosin 20% 500g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-hop',
              unitCode: 'BOX',
              unitName: 'Hộp',
            ),
            quantity: QuantityDto(quantityMicros: 3000000),
            unitPrice: MoneyDto(amountMinor: 596666, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 1790000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-003':
        return const [
          SalesOrderLineDto(
            lineId: 'line-003',
            product: ProductSnapshotDto(
              productId: 'prod-003',
              sku: 'VITC-100G',
              displayName: 'Vitamin C 100g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-goi',
              unitCode: 'BAG',
              unitName: 'Gói',
            ),
            quantity: QuantityDto(quantityMicros: 5000000),
            unitPrice: MoneyDto(amountMinor: 49000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 245000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-004':
        return const [
          SalesOrderLineDto(
            lineId: 'line-004-1',
            product: ProductSnapshotDto(
              productId: 'prod-004',
              sku: 'VETCLEAN-1L',
              displayName: 'Thuốc sát trùng VET-CLEAN 1L',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-chai',
              unitCode: 'BOT',
              unitName: 'Chai',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 445000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 445000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-004-2',
            product: ProductSnapshotDto(
              productId: 'prod-003',
              sku: 'VITC-100G',
              displayName: 'Vitamin C 100g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-goi',
              unitCode: 'BAG',
              unitName: 'Gói',
            ),
            quantity: QuantityDto(quantityMicros: 2000000),
            unitPrice: MoneyDto(amountMinor: 222500, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 445000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-005':
        return const [
          SalesOrderLineDto(
            lineId: 'line-005-1',
            product: ProductSnapshotDto(
              productId: 'prod-005',
              sku: 'TYLO-500G',
              displayName: 'Tylosin 20% 500g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-hop',
              unitCode: 'BOX',
              unitName: 'Hộp',
            ),
            quantity: QuantityDto(quantityMicros: 2000000),
            unitPrice: MoneyDto(amountMinor: 600000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 1200000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-005-2',
            product: ProductSnapshotDto(
              productId: 'prod-001',
              sku: 'AD3EC-5L',
              displayName: 'AD3EC 5L (tyx)',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-can',
              unitCode: 'CAN',
              unitName: 'Can',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-005-3',
            product: ProductSnapshotDto(
              productId: 'prod-003',
              sku: 'VITC-100G',
              displayName: 'Vitamin C 100g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-goi',
              unitCode: 'BAG',
              unitName: 'Gói',
            ),
            quantity: QuantityDto(quantityMicros: 2000000),
            unitPrice: MoneyDto(amountMinor: 200000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-006':
        return const [
          SalesOrderLineDto(
            lineId: 'line-006',
            product: ProductSnapshotDto(
              productId: 'prod-003',
              sku: 'VITC-100G',
              displayName: 'Vitamin C 100g',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-goi',
              unitCode: 'BAG',
              unitName: 'Gói',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 175000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 175000, currencyCode: 'VND'),
          ),
        ];
      case 'so-demo-008':
        return const [
          SalesOrderLineDto(
            lineId: 'line-008-1',
            product: ProductSnapshotDto(
              productId: 'prod-001',
              sku: 'AD3EC-5L',
              displayName: 'AD3EC 5L (tyx)',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-can',
              unitCode: 'CAN',
              unitName: 'Can',
            ),
            quantity: QuantityDto(quantityMicros: 1000000),
            unitPrice: MoneyDto(amountMinor: 2500000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 2500000, currencyCode: 'VND'),
          ),
          SalesOrderLineDto(
            lineId: 'line-008-2',
            product: ProductSnapshotDto(
              productId: 'prod-002',
              sku: 'AMOX-1KG',
              displayName: 'Amoxicillin 50% 1kg',
            ),
            unit: ProductUnitSnapshotDto(
              productUnitId: 'pu-hop',
              unitCode: 'BOX',
              unitName: 'Hộp',
            ),
            quantity: QuantityDto(quantityMicros: 2000000),
            unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 2000000, currencyCode: 'VND'),
          ),
        ];
      default:
        return [
          SalesOrderLineDto(
            lineId: 'line_1',
            product: const ProductSnapshotDto(
              productId: 'prod-001',
              sku: 'AD3EC-5L',
              displayName: 'AD3EC 5L (tyx)',
            ),
            unit: const ProductUnitSnapshotDto(
              productUnitId: 'pu-can',
              unitCode: 'CAN',
              unitName: 'Can',
            ),
            quantity: const QuantityDto(quantityMicros: 1000000),
            unitPrice: total,
            lineTotal: total,
          ),
        ];
    }
  }

  /// Raw sellable product snapshots.
  static List<ProductSnapshotDto> seedProducts() {
    return const <ProductSnapshotDto>[
      ProductSnapshotDto(
        productId: 'prod-001',
        sku: 'AD3EC-5L',
        displayName: 'AD3EC 5L (tyx)',
      ),
      ProductSnapshotDto(
        productId: 'prod-002',
        sku: 'AMOX-1KG',
        displayName: 'Amoxicillin 50% 1kg',
      ),
      ProductSnapshotDto(
        productId: 'prod-003',
        sku: 'VITC-100G',
        displayName: 'Vitamin C 100g',
      ),
      ProductSnapshotDto(
        productId: 'prod-004',
        sku: 'VETCLEAN-1L',
        displayName: 'Thuốc sát trùng VET-CLEAN 1L',
      ),
      ProductSnapshotDto(
        productId: 'prod-005',
        sku: 'TYLO-500G',
        displayName: 'Tylosin 20% 500g',
      ),
    ];
  }

  /// Raw draft list fixtures.
  static List<SalesOrderDraftDto> seedDrafts() {
    final savedAt = DateTime.utc(2026, 7, 28);
    return <SalesOrderDraftDto>[
      SalesOrderDraftDto(
        draftId: 'draft-001',
        version: 1,
        status: SalesDraftStatus.active,
        storeId: 'store-center',
        customer: getCustomerForDraft('draft-001'),
        savedAt: savedAt,
        savedByActorId: 'actor-1',
        lines: [
          SalesOrderDraftLineDto(
            lineId: 'dline-001-1',
            productId: 'prod-001',
            productSku: 'AD3EC-5L',
            productName: 'AD3EC 5L (tyx)',
            productUnitId: 'pu-can',
            unitCode: 'CAN',
            unitName: 'Can',
            quantity: const QuantityDto(quantityMicros: 1000000),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 1000000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          ),
          SalesOrderDraftLineDto(
            lineId: 'dline-001-2',
            productId: 'prod-003',
            productSku: 'VITC-100G',
            productName: 'Vitamin C 100g',
            productUnitId: 'pu-goi',
            unitCode: 'BAG',
            unitName: 'Gói',
            quantity: const QuantityDto(quantityMicros: 5000000),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 49000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 245000, currencyCode: 'VND'),
          ),
        ],
        total: const MoneyDto(amountMinor: 1245000, currencyCode: 'VND'),
      ),
      SalesOrderDraftDto(
        draftId: 'draft-002',
        version: 1,
        status: SalesDraftStatus.active,
        storeId: 'store-center',
        customer: getCustomerForDraft('draft-002'),
        savedAt: savedAt,
        savedByActorId: 'actor-1',
        lines: [
          SalesOrderDraftLineDto(
            lineId: 'dline-002-1',
            productId: 'prod-002',
            productSku: 'AMOX-1KG',
            productName: 'Amoxicillin 50% 1kg',
            productUnitId: 'pu-hop',
            unitCode: 'BOX',
            unitName: 'Hộp',
            quantity: const QuantityDto(quantityMicros: 2000000),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 1790000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 3580000, currencyCode: 'VND'),
          ),
        ],
        total: const MoneyDto(amountMinor: 3580000, currencyCode: 'VND'),
      ),
    ];
  }

  /// Resolves customer snapshot associated with a draft ID.
  static CustomerSnapshotDto getCustomerForDraft(String draftId) {
    switch (draftId) {
      case 'draft-001':
      case 'draft-demo-001':
        return const CustomerSnapshotDto(
          customerId: 'cust-001',
          displayName: 'Nguyễn Văn An',
          phoneNumber: '0903 456 789',
        );
      case 'draft-002':
      case 'draft-demo-002':
        return const CustomerSnapshotDto(
          customerId: 'cust-walk-in',
          displayName: 'Khách lẻ',
        );
      case 'draft-003':
      case 'draft-demo-003':
        return const CustomerSnapshotDto(
          customerId: 'cust-002',
          displayName: 'Công ty Minh Phát',
          phoneNumber: '028 3822 1122',
          taxCode: '0311111111',
        );
      default:
        return const CustomerSnapshotDto(
          customerId: 'cust-walk-in',
          displayName: 'Khách lẻ',
        );
    }
  }

  /// Resolves note associated with a draft ID.
  static String? getNoteForDraft(String draftId) {
    switch (draftId) {
      case 'draft-001':
      case 'draft-demo-001':
        return 'Giao trước 16:00';
      case 'draft-003':
      case 'draft-demo-003':
        return 'Cần xuất hóa đơn';
      default:
        return null;
    }
  }

  /// Resolves warning message associated with a draft ID.
  static String? getWarningForDraft(String draftId) {
    if (draftId == 'draft-003' || draftId == 'draft-demo-003') {
      return 'Giá hoặc sản phẩm cần kiểm tra lại';
    }
    return null;
  }
}
