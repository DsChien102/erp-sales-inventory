import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_detail_page.dart';

class _FakeReceiptRepo extends Fake implements GoodsReceiptRepository {
  ReceiptDetail? detail;
  Object? error;

  @override
  Future<ReceiptDetail> get(String receiptId) async {
    if (error != null) throw error!;
    if (detail != null) return detail!;
    throw const AppException('NOT_FOUND');
  }
}

void main() {
  late _FakeReceiptRepo repository;

  final sampleDetail = ReceiptDetail(
    header: const ReceiptHeader(
      receiptId: 'rc-1',
      receiptNo: 'PN-261110-01',
      supplierId: 's-1',
      supplierName: 'Công ty Á Châu',
      supplierIsSystem: false,
      supplierDocNo: 'HD-999',
      businessDate: '2026-11-10',
      warehouseName: 'Kho trung tâm',
      freightCostVnd: 50000,
      tradeDiscountVnd: 20000,
      purchaseTotalVnd: 1000000,
      landedTotalVnd: 1030000,
      lineCount: 1,
      lotCount: 1,
      createdByName: 'Nguyễn Văn Kho',
      createdAt: '2026-11-10T08:00:00Z',
    ),
    lines: const [
      ReceiptDetailLine(
        lineId: 'line-1',
        lineNo: 1,
        productId: 'p-1',
        productName: 'Nobivac DHPPi',
        productCode: 'NOB-1',
        baseUom: 'hộp',
        unitName: 'hộp',
        conversionRate: 1,
        paidQty: 10,
        freeQty: 0,
        unitPriceVnd: 100000,
        grossAmountVnd: 1000000,
        tierDiscountPercent: null,
        tierDiscountVnd: 0,
        purchaseAmountVnd: 1000000,
        allocatedFreightVnd: 50000,
        allocatedDiscountVnd: 20000,
        landedAmountVnd: 1030000,
        landedUnitCost: 103000,
        lots: [
          ReceiptDetailLot(
            lotCode: 'LOT-2026',
            quantity: 10,
            allocatedLandedCostVnd: 1030000,
          ),
        ],
      ),
    ],
  );

  setUp(() {
    repository = _FakeReceiptRepo();
  });

  Widget buildApp(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('ReceiptDetailPage', () {
    testWidgets('detail_readonly_allocation_390', (tester) async {
      repository.detail = sampleDetail;

      await tester.pumpWidget(
        buildApp(
          RepositoryProvider<GoodsReceiptRepository>.value(
            value: repository,
            child: const ReceiptDetailPage(receiptId: 'rc-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hiển thị thông tin header
      expect(find.text('Phiếu nhận PN-261110-01'), findsOneWidget);
      expect(find.text('Công ty Á Châu · HĐ: HD-999 · 2026-11-10'), findsOneWidget);
      expect(find.text('Kho trung tâm'), findsOneWidget);
      expect(find.text('Nguyễn Văn Kho'), findsOneWidget);

      // Dải tài chính hiển thị giá trị đã lưu
      expect(find.text('1.000.000 đ'), findsWidgets);
      expect(find.text('50.000 đ'), findsWidgets);
      expect(find.text('20.000 đ'), findsWidgets);
      expect(find.text('1.030.000 đ'), findsWidgets);

      // Dòng hàng hiển thị giá gốc đã lưu
      expect(find.text('Nobivac DHPPi (hộp)'), findsOneWidget);
      expect(find.text('Giá gốc đã lưu'), findsOneWidget);
      expect(find.text('LOT-2026'), findsOneWidget);
    });

    testWidgets('detail_not_found', (tester) async {
      repository.error = const AppException('NOT_FOUND');

      await tester.pumpWidget(
        buildApp(
          RepositoryProvider<GoodsReceiptRepository>.value(
            value: repository,
            child: const ReceiptDetailPage(receiptId: 'non-existent'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy phiếu nhận hàng.'), findsOneWidget);
    });
  });
}

class InheritedRepository extends InheritedWidget {
  const InheritedRepository({
    super.key,
    required this.repository,
    required super.child,
  });

  final GoodsReceiptRepository repository;

  @override
  bool updateShouldNotify(InheritedRepository oldWidget) => false;
}
