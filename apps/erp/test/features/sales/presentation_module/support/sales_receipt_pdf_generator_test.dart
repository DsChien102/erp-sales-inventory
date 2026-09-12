import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SalesReceiptPdfGenerator', () {
    test('generates non-empty PDF bytes from typed document data', () async {
      final first = _documentA();
      final second = _documentB();

      final firstBytes = await SalesReceiptPdfGenerator.generate(first);
      final secondBytes = await SalesReceiptPdfGenerator.generate(second);

      expect(firstBytes, isNotEmpty);
      expect(secondBytes, isNotEmpty);
      expect(firstBytes.length, greaterThan(100));
      expect(secondBytes.length, greaterThan(100));
      expect(firstBytes, isNot(equals(secondBytes)));
    });

    test('prints original sale and settlement adjustment as separate labels', () {
      final rows = SalesReceiptPdfGenerator.summaryRows(_documentWithReturn());
      final labels = rows.map((row) => row.$1).toList();

      expect(labels, contains('Giá trị đơn gốc'));
      expect(labels, isNot(contains('Tổng đơn')));
      expect(rows, contains(('Giá trị đơn gốc', '1.000.000đ')));
      expect(rows, contains(('Điều chỉnh sau bán', '-200.000đ')));
      expect(rows, contains(('Phải trả hiện tại', '800.000đ')));
      expect(rows, contains(('Còn phải thu', '800.000đ')));
    });

    test('keeps Tổng đơn when a legacy receipt has no settlement block', () {
      final rows = SalesReceiptPdfGenerator.summaryRows(_documentA());
      expect(rows.map((row) => row.$1), contains('Tổng đơn'));
      expect(rows.map((row) => row.$1), isNot(contains('Điều chỉnh sau bán')));
    });

    test('sanitizes filename from receipt number', () {
      final fileName = SalesReceiptPdfGenerator.sanitizeFileName('PBH/2026:08:12*001');
      expect(fileName, 'PBH_2026_08_12_001.pdf');
    });

    test('rejects legacy hardcoded sales literals in receipt renderer sources', () {
      const forbidden = <String>[
        'ĐẠI LÝ THUỐC THÚ Y MẬU HIÊN',
        '0915 568 901',
        'PBH-20260722-0129',
        'DH-000129',
        'Nguyễn Văn An',
        '4.445.238đ',
        'AD3EC 5L',
      ];

      // flutter test cwd is the package root (`apps/erp`).
      final root = Directory.current.path;
      final sources = <String>[
        '$root/lib/features/sales/presentation/support/sales_receipt_pdf_generator.dart',
        '$root/lib/features/sales/presentation/pages/sales_receipt_preview_page.dart',
      ];

      for (final source in sources) {
        final content = File(source).readAsStringSync();
        for (final literal in forbidden) {
          expect(
            content.contains(literal),
            isFalse,
            reason: 'Found forbidden literal "$literal" in $source',
          );
        }
      }
    });
  });
}

SalesReceiptDocumentDto _documentA() => SalesReceiptDocumentDto(
  receiptNumber: 'PBH-20260812-0001',
  orderNumber: 'SO-0001',
  soldAt: DateTime.utc(2026, 8, 12, 2, 41),
  store: const StoreSnapshotDto(
    storeId: 'store-a',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'seller-a', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-a',
    displayName: 'Trần Thu',
    phoneNumber: '0903000111',
  ),
  lines: const <SalesReceiptLineDto>[
    SalesReceiptLineDto(
      lineId: 'line-a1',
      product: ProductSnapshotDto(
        productId: 'product-a1',
        sku: 'SKU-A1',
        displayName: 'Vaccine A',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-a1',
        unitCode: 'VIAL',
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
    ),
  ],
  subtotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  discountTotal: const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
  orderTotal: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
  paidTotal: const MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
  outstandingTotal: const MoneyDto(amountMinor: 40000, currencyCode: 'VND'),
  payments: const <PaymentIntentSummaryDto>[
    PaymentIntentSummaryDto(
      method: SalesPaymentMethod.cash,
      amount: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
      status: SalesPaymentStatus.confirmed,
    ),
  ],
  dueAt: DateTime.utc(2026, 8, 30),
);

SalesReceiptDocumentDto _documentWithReturn() => SalesReceiptDocumentDto(
  receiptNumber: 'PBH-20260812-0003',
  orderNumber: 'SO-0003',
  soldAt: DateTime.utc(2026, 8, 12, 4, 0),
  store: const StoreSnapshotDto(
    storeId: 'store-c',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'seller-c', displayName: 'Minh Anh'),
  lines: const <SalesReceiptLineDto>[
    SalesReceiptLineDto(
      lineId: 'line-c1',
      product: ProductSnapshotDto(
        productId: 'product-c1',
        sku: 'SKU-C1',
        displayName: 'Vaccine C',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-c1',
        unitCode: 'VIAL',
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
  subtotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
  discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  orderTotal: const MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
  paidTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  outstandingTotal: const MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
  payments: const <PaymentIntentSummaryDto>[],
  settlementSnapshot: const SalesReceiptSettlementSnapshotDto(
    originalPayable: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    adjustment: MoneyDto(amountMinor: -200000, currencyCode: 'VND'),
    currentPayable: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
    collected: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    refunded: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    netCollected: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    outstanding: MoneyDto(amountMinor: 800000, currencyCode: 'VND'),
  ),
);

SalesReceiptDocumentDto _documentB() => SalesReceiptDocumentDto(
  receiptNumber: 'PBH-20260812-0002',
  orderNumber: 'SO-0002',
  soldAt: DateTime.utc(2026, 8, 12, 3, 20),
  store: const StoreSnapshotDto(
    storeId: 'store-b',
    storeCode: 'DN-02',
    displayName: 'Chi nhánh Đà Nẵng',
  ),
  seller: const ActorSnapshotDto(actorId: 'seller-b', displayName: 'Phương Hà'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-b',
    displayName: 'Lê Gia',
    phoneNumber: '0988777666',
  ),
  lines: const <SalesReceiptLineDto>[
    SalesReceiptLineDto(
      lineId: 'line-b1',
      product: ProductSnapshotDto(
        productId: 'product-b1',
        sku: 'SKU-B1',
        displayName: 'Khoáng chất B',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-b1',
        unitCode: 'BOX',
        unitName: 'Hộp',
      ),
      quantity: QuantityDto(quantityMicros: 2 * QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 75000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
    ),
  ],
  subtotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  discountTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  orderTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  paidTotal: const MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
  outstandingTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  payments: const <PaymentIntentSummaryDto>[
    PaymentIntentSummaryDto(
      method: SalesPaymentMethod.manualBankTransfer,
      amount: MoneyDto(amountMinor: 150000, currencyCode: 'VND'),
      status: SalesPaymentStatus.confirmed,
    ),
  ],
);
