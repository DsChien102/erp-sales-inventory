import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SalesSlipPdfGenerator', () {
    test('throws unsupported for sales slip generation', () async {
      expect(
        () => SalesSlipPdfGenerator.generate(type: SalesSlipType.sales),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('requires authoritative detail for return exchange PDF', () async {
      expect(
        () => SalesSlipPdfGenerator.generate(
          type: SalesSlipType.returnExchange,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generates PDF from SalesReturnExchangeDetailVm without defaults', () async {
      final bytes = await SalesSlipPdfGenerator.generateReturnExchange(
        detail: _detail(referenceNumber: 'RE-42'),
        orderNumber: 'SO-1',
        customerDisplayName: 'Khách A',
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('sanitizes filename from backend reference number', () {
      expect(
        SalesSlipPdfGenerator.sanitizeFileName('RE/2026:08*01'),
        'RE_2026_08_01.pdf',
      );
    });

    test('refund on an order with debt adds a debt-reduction row to the refund template', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: -400000,
        collectAmountMinor: 0,
        refundAmountMinor: 100000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 300000,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 100000,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Cần hoàn tiền', '100.000đ'),
        ('Giảm nợ đơn', '300.000đ'),
        ('Đã hoàn', '100.000đ'),
      ]);
    });

    test('collect follows the template: Phải thu thêm · Đã thu · Công nợ phát sinh', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: 254762,
        collectAmountMinor: 254762,
        refundAmountMinor: 0,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 150000,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 104762,
        remainderRefundMinor: 0,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Phải thu thêm', '254.762đ'),
        ('Đã thu', '150.000đ'),
        ('Công nợ phát sinh', '104.762đ'),
      ]);
    });

    test('zero difference follows the template: Không chênh lệch 0đ', () {
      const plan = ReturnExchangeSettlementPlanDto(
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
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Không chênh lệch', '0đ'),
      ]);
    });

    test('plain refund follows the template: Cần hoàn tiền · Đã hoàn', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: -50000,
        collectAmountMinor: 0,
        refundAmountMinor: 50000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 50000,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Cần hoàn tiền', '50.000đ'),
        ('Đã hoàn', '50.000đ'),
      ]);
    });

    test('rejects demo literals in return-slip production sources', () {
      const forbidden = <String>[
        'PDT-20260722-0018',
        'DH-000129',
        'DT-00018',
        'Nguyễn Văn An',
        '0903 456 789',
        '22/07/2026',
        'AD3EC 5L (tyx)',
        '150.000đ',
        '104.762đ',
        '4.700.000đ',
        '1.200.000đ',
      ];

      // flutter test cwd is the package root (`apps/erp`).
      final root = Directory.current.path;
      final sources = <String>[
        '$root/lib/features/sales/presentation/support/sales_slip_pdf_generator.dart',
        '$root/lib/features/sales/presentation/pages/sales_slip_preview_page.dart',
      ];

      for (final source in sources) {
        expect(File(source).existsSync(), isTrue, reason: source);
        final content = File(source).readAsStringSync();
        for (final literal in forbidden) {
          expect(
            content.contains(literal),
            isFalse,
            reason: '$source still contains demo literal "$literal"',
          );
        }
      }
    });
  });
}

SalesReturnExchangeDetailVm _detail({required String referenceNumber}) {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -50000,
    collectAmountMinor: 0,
    refundAmountMinor: 50000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 50000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );
  return SalesReturnExchangeDetailVm(
    returnExchangeId: 'return-1',
    salesOrderId: 'order-1',
    referenceNumber: referenceNumber,
    status: ReturnExchangeStatus.completed,
    version: 2,
    createdAt: DateTime.utc(2026, 8, 13, 9),
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    completedAt: DateTime.utc(2026, 8, 13, 11),
    lines: const [
      ReturnExchangeDetailLineDto(
        lineId: 'line-r1',
        kind: ReturnExchangeLineKind.returnLine,
        product: ProductSnapshotDto(
          productId: 'p1',
          sku: 'SKU-1',
          displayName: 'Vaccine A',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'u1',
          unitCode: 'LO',
          unitName: 'Lọ',
        ),
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        originalSalesOrderLineId: 'sol-1',
        reasonCode: 'DAMAGED',
        conditionCode: 'OPENED',
      ),
    ],
    valuation: const ReturnExchangeValuationDto(
      returnValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      exchangeValue: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
      settlementDifference: MoneyDto(amountMinor: -50000, currencyCode: 'VND'),
      settlementPlan: plan,
      sourceOrderVersion: 7,
    ),
    settlementPlan: plan,
    completionReady: false,
  );
}
