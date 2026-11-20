import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/reports/supplier_purchase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'reports_test_support.dart';

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository()..supplierResult = supplierReportOf();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget page({Size size = const Size(390, 844)}) => reportsApp(
        SupplierPurchasePage(clock: () => reportsToday, onBack: () {}),
        size: size,
      );

  group('SupplierPurchasePage', () {
    testWidgets('supplier_list_390', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Nhập hàng theo NCC'), findsOneWidget);
      expect(
        find.textContaining('Tổng giá gốc', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('45.200.000đ', findRichText: true), findsOneWidget);
      expect(find.text('Cty Thú y A'), findsOneWidget);
      expect(find.text('3 phiếu'), findsOneWidget);
      expect(find.text('Giá gốc 30.080.000đ'), findsOneWidget);
      expect(find.text('Mua lẻ / khác'), findsOneWidget);
    });

    testWidgets('supplier_list_1280 shows 7 columns', (tester) async {
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      for (final h in [
        'NHÀ CUNG CẤP',
        'SỐ PHIẾU',
        'TIỀN MUA',
        'CHI PHÍ THU MUA',
        'CHIẾT KHẤU THƯƠNG MẠI',
        'GIÁ GỐC',
        'CHIẾT KHẤU ĐẠT MỐC',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
    });

    testWidgets('supplier_sheet_products', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cty Thú y A'));
      await tester.pumpAndSettle();

      expect(find.text('Chiết khấu đạt mốc'), findsOneWidget);
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('Mua 10 · Tặng 1 hộp'), findsOneWidget);
      expect(find.text('Đơn giá gốc 93.636,36 đ/hộp'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);
    });

    testWidgets('supplier_sheet_without_rebate_hides_row', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mua lẻ / khác'));
      await tester.pumpAndSettle();
      expect(find.text('Chiết khấu đạt mốc'), findsNothing);
    });

    testWidgets('supplier_empty', (tester) async {
      repo.supplierResult = supplierReportOf(empty: true);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Chưa nhập hàng trong kỳ'), findsOneWidget);
      expect(find.text('Đổi khoảng ngày để xem dữ liệu khác.'), findsOneWidget);
    });

    testWidgets('supplier_denied_390', (tester) async {
      repo.error = const AppException(InventoryErrorCode.permissionDenied);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa có quyền xem báo cáo nhập hàng'), findsOneWidget);
      expect(find.text('Chỉ chủ cửa hàng xem báo cáo nhập hàng.'), findsOneWidget);
      expect(findMoneyText(), findsNothing);
    });
  });
}
