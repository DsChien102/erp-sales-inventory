import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_result_page.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget buildApp(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  const sampleResult = RecordReceiptResult(
    receiptId: 'rc-1',
    receiptNo: 'PN-261110-01',
    supplierName: 'Công ty Á Châu',
    supplierDocNo: 'HD-999',
    businessDate: '2026-11-10',
    lineCount: 2,
    lotCount: 3,
    landedTotalVnd: 5500000,
    createdByName: 'Nguyễn Văn Kho',
    stockChanges: [
      K4StockChangeData(
        productName: 'Nobivac DHPPi',
        baseUom: 'hộp',
        before: 10,
        after: 25,
      ),
    ],
    reachedPrograms: [
      ReceiptReachedProgram(
        programId: 'prog-bonus-q4',
        name: 'Thưởng quý 4 đạt mốc 50tr',
      ),
    ],
  );

  group('ReceiptResultPage', () {
    testWidgets('result_shows_reached_program_and_facts', (tester) async {
      String? viewReceiptTapped;
      var viewStockTapped = false;
      var receiptNextTapped = false;

      await tester.pumpWidget(
        buildApp(
          ReceiptResultPage(
            result: sampleResult,
            onViewReceipt: (id) => viewReceiptTapped = id,
            onViewStock: () => viewStockTapped = true,
            onNewReceipt: () => receiptNextTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề kết quả
      expect(find.text('Ghi nhận hàng thành công'), findsOneWidget);
      expect(find.text('PN-261110-01'), findsWidgets);
      expect(find.text('Công ty Á Châu'), findsOneWidget);
      expect(find.text('HD-999'), findsOneWidget);
      expect(find.text('Nguyễn Văn Kho'), findsOneWidget);

      // Chương trình đạt mốc
      expect(find.text('Thưởng quý 4 đạt mốc 50tr'), findsOneWidget);

      // Thay đổi tồn kho
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('10 → 25 hộp'), findsOneWidget);

      // Nút liên kết xem phiếu
      final viewReceiptLink = find.text('Xem phiếu PN-261110-01');
      expect(viewReceiptLink, findsOneWidget);
      await tester.ensureVisible(viewReceiptLink);
      await tester.tap(viewReceiptLink);
      await tester.pump();
      expect(viewReceiptTapped, 'rc-1');

      // Các nút hành động
      final viewStockBtn = find.text('Xem tồn kho');
      expect(viewStockBtn, findsOneWidget);
      await tester.ensureVisible(viewStockBtn);
      await tester.tap(viewStockBtn);
      await tester.pump();
      expect(viewStockTapped, isTrue);

      final nextReceiptBtn = find.text('Nhận tiếp');
      expect(nextReceiptBtn, findsOneWidget);
      await tester.ensureVisible(nextReceiptBtn);
      await tester.tap(nextReceiptBtn);
      await tester.pump();
      expect(receiptNextTapped, isTrue);
    });
  });
}
