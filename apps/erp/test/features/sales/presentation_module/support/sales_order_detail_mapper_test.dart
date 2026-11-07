import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart' as app;
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_detail_vm.dart';
import 'package:erp/features/sales/presentation/support/sales_order_detail_mapper.dart';

void main() {
  group('SalesOrderDetailMapper', () {
    test('maps exact dto committed date customer store seller note lines and lifecycle', () {
      final dto = _detailDto(
        salesOrderId: 'so-demo-006',
        orderNumber: 'DH-000129-d04-return',
        version: 7,
        committedAt: DateTime.utc(2026, 8, 12, 3, 15),
        lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
        customerName: 'Đại lý An Bình',
        customerPhone: '0903456789',
        storeName: 'Chi nhánh Quận 1',
        sellerName: 'Minh Anh',
        orderNote: 'Giao giờ hành chính',
        productName: 'Vaccine A',
        unitName: 'Lọ',
        quantityMicros: 2000000,
        unitPriceMinor: 625000,
        lineTotalMinor: 1250000,
        totalMinor: 1250000,
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.orderId, 'so-demo-006');
      expect(vm.orderNumber, 'DH-000129-d04-return');
      expect(vm.orderVersion, 7);
      expect(vm.createdAtFormatted, '12/08/2026 10:15');
      expect(vm.customerName, 'Đại lý An Bình');
      expect(vm.customerId, 'customer-1');
      expect(vm.customerPhone, '0903456789');
      expect(vm.storeName, 'Chi nhánh Quận 1');
      expect(vm.sellerName, 'Minh Anh');
      expect(vm.note, 'Giao giờ hành chính');
      expect(vm.lifecycleStatus, SalesOrderLifecycleStatus.committed);
      expect(vm.totalAmountMinor, 1250000);
      expect(vm.items, hasLength(1));
      expect(vm.items.single.productName, 'Vaccine A');
      expect(vm.items.single.unitName, 'Lọ');
      expect(vm.items.single.quantity, 2);
      expect(vm.items.single.unitPriceMinor, 625000);
      expect(vm.items.single.totalAmountMinor, 1250000);
      expect(vm.paidAmountMinor, 0);
      expect(vm.timeline, isEmpty);
      expect(vm.returnExchangeSlips, isEmpty);
      expect(vm.cancelReason, isNull);
    });

    test('does not infer cancelled payment or return state from order id', () {
      final dto = _detailDto(
        salesOrderId: 'so-demo-008-cancel-return-d06',
        orderNumber: 'DH-000129-d06-cancel',
        version: 3,
        committedAt: DateTime.utc(2026, 8, 1, 9, 0),
        lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
        customerName: 'Công ty Minh Phát',
        customerPhone: '0911000000',
        storeName: 'Chi nhánh Đà Nẵng',
        sellerName: 'Phương Hà',
        orderNote: null,
        productName: 'Khoáng chất B',
        unitName: 'Hộp',
        quantityMicros: 1000000,
        unitPriceMinor: 4700000,
        lineTotalMinor: 4700000,
        totalMinor: 4700000,
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.lifecycleStatus, isNot(SalesOrderLifecycleStatus.cancelled));
      expect(vm.customerName, isNot('Nguyễn Văn An'));
      expect(vm.createdAtFormatted, isNot('29/07/2026 10:32'));
      expect(vm.paidAmountMinor, isNot(3372619));
      expect(vm.returnExchangeSlips, isEmpty);
      expect(vm.timeline, isEmpty);
      expect(vm.cancelReason, isNull);
      expect(vm.customerName, 'Công ty Minh Phát');
      expect(vm.storeName, 'Chi nhánh Đà Nẵng');
      expect(vm.sellerName, 'Phương Hà');
      expect(vm.createdAtFormatted, '01/08/2026 16:00');
    });

    test('strikes through the list price when the original line has a discount', () {
      final dto = _detailDto(
        salesOrderId: 'order-discount',
        orderNumber: 'SO-2026-00002',
        version: 1,
        committedAt: DateTime.utc(2026, 9, 28, 3, 0),
        lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
        customerName: 'Đại lý An Bình',
        customerPhone: '0903456789',
        storeName: 'Chi nhánh Quận 1',
        sellerName: 'Minh Anh',
        orderNote: null,
        productName: 'Vaccine A',
        unitName: 'Lọ',
        quantityMicros: 2000000,
        unitPriceMinor: 100000,
        lineTotalMinor: 180000,
        discountTotalMinor: 20000,
        totalMinor: 180000,
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.items.single.originalUnitPriceMinor, 100000);
      expect(vm.items.single.unitPriceMinor, 90000);
      expect(vm.items.single.totalAmountMinor, 180000);
    });

    test('keeps the unit price when the original line has no discount', () {
      final dto = _detailDto(
        salesOrderId: 'order-list',
        orderNumber: 'SO-2026-00003',
        version: 1,
        committedAt: DateTime.utc(2026, 9, 28, 3, 0),
        lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
        customerName: null,
        customerPhone: null,
        storeName: 'Chi nhánh Quận 1',
        sellerName: 'Minh Anh',
        orderNote: null,
        productName: 'Vaccine A',
        unitName: 'Lọ',
        quantityMicros: 1000000,
        unitPriceMinor: 100000,
        lineTotalMinor: 100000,
        totalMinor: 100000,
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.items.single.originalUnitPriceMinor, isNull);
      expect(vm.items.single.unitPriceMinor, 100000);
    });

    test('maps the current line original unit price when the server sends one', () {
      final dto = _detailDto(
        salesOrderId: 'order-current',
        orderNumber: 'SO-2026-00004',
        version: 2,
        committedAt: DateTime.utc(2026, 9, 28, 3, 0),
        lifecycleStatus: app.SalesOrderLifecycleStatus.completed,
        customerName: null,
        customerPhone: null,
        storeName: 'Chi nhánh Quận 1',
        sellerName: 'Minh Anh',
        orderNote: null,
        productName: 'Vaccine A',
        unitName: 'Lọ',
        quantityMicros: 2000000,
        unitPriceMinor: 100000,
        lineTotalMinor: 180000,
        totalMinor: 180000,
        currentLines: [
          app.SalesOrderCurrentLineDto(
            product: const app.ProductSnapshotDto(
              productId: 'product-1',
              sku: 'SKU-1',
              displayName: 'Vaccine A',
            ),
            unit: const app.ProductUnitSnapshotDto(
              productUnitId: 'unit-1',
              unitCode: 'UNIT',
              unitName: 'Lọ',
            ),
            heldQuantity: const app.QuantityDto(quantityMicros: 2000000),
            unitPrice: const app.MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
            originalUnitPrice: const app.MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
            source: app.SalesOrderLineSource.original,
          ),
        ],
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.currentItems.single.originalUnitPriceMinor, 100000);
      expect(vm.currentItems.single.unitPriceMinor, 90000);
    });

    test('maps cancelled lifecycle and nullable customer from dto only', () {
      final dto = _detailDto(
        salesOrderId: 'order-walk-in',
        orderNumber: 'SO-2026-00001',
        version: 1,
        committedAt: DateTime.utc(2026, 7, 29, 10, 32),
        lifecycleStatus: app.SalesOrderLifecycleStatus.cancelled,
        customerName: null,
        customerPhone: null,
        storeName: 'Kho trung tâm',
        sellerName: 'Thu Ngân',
        orderNote: 'Khách không nhận hàng',
        productName: 'Men tiêu hóa C',
        unitName: 'Gói',
        quantityMicros: 1000000,
        unitPriceMinor: 30000,
        lineTotalMinor: 30000,
        totalMinor: 30000,
      );

      final vm = SalesOrderDetailMapper.toVm(dto);

      expect(vm.lifecycleStatus, SalesOrderLifecycleStatus.cancelled);
      expect(vm.customerName, 'Khách lẻ');
      expect(vm.customerPhone, '');
      expect(vm.note, 'Khách không nhận hàng');
      expect(vm.sellerName, 'Thu Ngân');
      expect(vm.createdAtFormatted, '29/07/2026 17:32');
    });

    test('toCancellationVm maps authoritative fields with no refund concept', () {
      final dto = app.SalesOrderCancellationDetailDto(
        result: const app.SalesOrderCancellationResultDto(
          cancellationId: 'cancel-9',
          salesOrderId: 'order-1',
          salesOrderVersion: 8,
          status: app.SalesOrderCancellationStatus.confirmed,
        ),
        reason: const app.CancellationReasonDto(
          reasonText: 'Khách nhập trùng đơn',
        ),
        cancelledAt: DateTime.utc(2026, 8, 12, 4, 0),
        cancelledByActorId: 'actor-77',
        cancelledByActorName: 'Minh Anh',
        netConfirmedCollectionMinor: 0,
      );

      final vm = SalesOrderDetailMapper.toCancellationVm(dto);

      expect(vm.cancellationId, 'cancel-9');
      expect(vm.reason, 'Khách nhập trùng đơn');
      expect(vm.cancelledByActorId, 'actor-77');
      expect(vm.cancelledByActorName, 'Minh Anh');
      expect(vm.isProcessing, isFalse);
      expect(vm.statusLabel, 'Đã hủy');
      expect(vm.netConfirmedCollectionFormatted, isNotEmpty);
    });

    test('toCancellationVm leaves reason empty when text is blank', () {
      final dto = app.SalesOrderCancellationDetailDto(
        result: const app.SalesOrderCancellationResultDto(
          cancellationId: 'cancel-9',
          salesOrderId: 'order-1',
          salesOrderVersion: 8,
          status: app.SalesOrderCancellationStatus.processing,
        ),
        reason: const app.CancellationReasonDto(
          reasonText: '',
        ),
        cancelledAt: DateTime.utc(2026, 8, 12, 4, 0),
        cancelledByActorId: 'actor-77',
        netConfirmedCollectionMinor: 0,
      );

      final vm = SalesOrderDetailMapper.toCancellationVm(dto);

      expect(vm.reason, isEmpty);
      expect(vm.isProcessing, isTrue);
      expect(vm.statusLabel, 'Đang xử lý hủy');
    });
  });
}

app.SalesOrderDetailDto _detailDto({
  required String salesOrderId,
  required String orderNumber,
  required int version,
  required DateTime committedAt,
  required app.SalesOrderLifecycleStatus lifecycleStatus,
  required String? customerName,
  required String? customerPhone,
  required String storeName,
  required String sellerName,
  required String? orderNote,
  required String productName,
  required String unitName,
  required int quantityMicros,
  required int unitPriceMinor,
  required int lineTotalMinor,
  int? discountTotalMinor,
  required int totalMinor,
  List<app.SalesOrderCurrentLineDto> currentLines = const [],
}) {
  return app.SalesOrderDetailDto(
    order: app.SalesOrderDto(
      salesOrderId: salesOrderId,
      orderNumber: orderNumber,
      version: version,
      lifecycleStatus: lifecycleStatus,
      lockStatus: app.SalesOrderLockStatus.unlocked,
      total: app.MoneyDto(amountMinor: totalMinor, currencyCode: 'VND'),
    ),
    committedAt: committedAt,
    store: app.StoreSnapshotDto(
      storeId: 'store-1',
      storeCode: 'HCM-01',
      displayName: storeName,
    ),
    seller: app.ActorSnapshotDto(actorId: 'seller-1', displayName: sellerName),
    customer: customerName == null
        ? null
        : app.CustomerSnapshotDto(
            customerId: 'customer-1',
            displayName: customerName,
            phoneNumber: customerPhone,
          ),
    lines: [
      app.SalesOrderLineDto(
        lineId: 'line-1',
        product: app.ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-1',
          displayName: productName,
        ),
        unit: app.ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'UNIT',
          unitName: unitName,
        ),
        quantity: app.QuantityDto(quantityMicros: quantityMicros),
        unitPrice: app.MoneyDto(amountMinor: unitPriceMinor, currencyCode: 'VND'),
        lineTotal: app.MoneyDto(amountMinor: lineTotalMinor, currencyCode: 'VND'),
        discountTotal: discountTotalMinor == null
            ? null
            : app.MoneyDto(amountMinor: discountTotalMinor, currencyCode: 'VND'),
      ),
    ],
    orderNote: orderNote,
    currentReceiptId: 'receipt-1',
    currentLines: currentLines,
  );
}
