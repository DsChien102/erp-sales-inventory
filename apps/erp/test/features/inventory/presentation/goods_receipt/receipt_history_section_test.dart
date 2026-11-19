import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_history_section.dart';

class _FakeReceiptRepo extends Fake implements GoodsReceiptRepository {
  List<ReceiptListRow> rows = [];

  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async {
    return rows;
  }
}

void main() {
  late _FakeReceiptRepo repository;

  final sampleRows = [
    const ReceiptListRow(
      receiptId: 'rc-1',
      receiptNo: 'PN-261110-01',
      supplierId: 's-1',
      supplierName: 'Công ty Á Châu',
      supplierIsSystem: false,
      businessDate: '2026-11-10',
      lineCount: 2,
      lotCount: 3,
      landedTotalVnd: 5500000,
      createdByName: 'Nguyễn Văn Kho',
      createdAt: '2026-11-10T08:00:00Z',
    ),
  ];

  setUp(() {
    repository = _FakeReceiptRepo();
  });

  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('ReceiptHistorySection', () {
    testWidgets('history_rows_and_see_all', (tester) async {
      repository.rows = sampleRows;
      var seeAllTapped = false;
      String? receiptTapped;

      await tester.pumpWidget(
        buildApp(
          ReceiptHistorySection(
            supplierId: 's-1',
            repository: repository,
            onViewAll: () => seeAllTapped = true,
            onOpenReceipt: (id) => receiptTapped = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử nhập hàng'), findsOneWidget);
      expect(find.text('PN-261110-01'), findsOneWidget);
      expect(find.text('5.500.000 đ'), findsOneWidget);

      final seeAllBtn = find.text('Xem tất cả');
      expect(seeAllBtn, findsOneWidget);
      await tester.tap(seeAllBtn);
      expect(seeAllTapped, isTrue);

      await tester.tap(find.text('PN-261110-01'));
      expect(receiptTapped, 'rc-1');
    });

    testWidgets('history_empty', (tester) async {
      repository.rows = [];

      await tester.pumpWidget(
        buildApp(
          ReceiptHistorySection(
            supplierId: 's-1',
            repository: repository,
            onViewAll: () {},
            onOpenReceipt: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lịch sử nhập hàng từ nhà cung cấp này.'), findsOneWidget);
    });
  });
}

