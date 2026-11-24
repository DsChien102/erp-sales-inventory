import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/reports/gross_profit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'reports_test_support.dart';

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository()
      ..grossProductResult = grossProductOf()
      ..grossOrderResult = grossOrderOf();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget page({Size size = const Size(390, 844), ValueChanged<String>? onOpenOrder}) {
    return reportsApp(
      GrossProfitPage(
        clock: () => reportsToday,
        onOpenOrder: onOpenOrder ?? (_) {},
        onBack: () {},
      ),
      size: size,
    );
  }

  group('GrossProfitPage', () {
    testWidgets('gross_profit_product_390', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Lãi gộp'), findsAtLeastNWidgets(2)); // tiêu đề + thẻ tổng
      expect(find.text('Theo sản phẩm'), findsOneWidget);
      expect(find.text('Theo đơn'), findsOneWidget);
      for (final l in [
        'Doanh thu thuần',
        'Giá vốn',
        'Hao hụt / huỷ',
        'Lãi sau hao hụt',
      ]) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
      expect(find.text('Amoxicillin 500mg'), findsOneWidget);
      expect(
        find.textContaining('DT 5.200.000đ · GV 3.380.000đ'),
        findsOneWidget,
      );
      expect(find.textContaining('Lãi +1.820.000 đ · 35,0%'), findsOneWidget);
    });

    testWidgets('gross_profit_product_1280', (tester) async {
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      for (final h in [
        'SẢN PHẨM',
        'DOANH THU THUẦN',
        'GIÁ VỐN LÚC BÁN',
        'ĐIỀU CHỈNH',
        'CHIẾT KHẤU NCC',
        'GIÁ VỐN SAU ĐIỀU CHỈNH',
        'LÃI GỘP',
        'TỶ LỆ',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('+20.000 đ'), findsOneWidget);
      expect(find.text('−3.500.000 đ'), findsOneWidget);
      expect(find.text('35,0%'), findsOneWidget);
    });

    testWidgets('gross_profit_product_sheet shows 9 rows', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amoxicillin 500mg'));
      await tester.pumpAndSettle();

      for (final l in [
        'Doanh thu',
        'Giảm trừ (trả / huỷ)',
        'Doanh thu thuần',
        'Giá vốn lúc bán',
        'Điều chỉnh',
        'Chiết khấu NCC',
        'Giá vốn sau điều chỉnh',
        'Lãi gộp',
        'Tỷ lệ',
      ]) {
        expect(find.text(l), findsWidgets, reason: l);
      }
      expect(find.text('Đóng'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Đóng'), findsNothing);
    });

    testWidgets('gross_profit_order_mode', (tester) async {
      String? opened;
      await tester.pumpWidget(page(onOpenOrder: (id) => opened = id));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theo đơn'));
      await tester.pumpAndSettle();

      expect(repo.grossPeriods, hasLength(2));
      expect(find.text('DH-0001'), findsOneWidget);
      expect(find.text('Giá tạm'), findsOneWidget);
      expect(
        find.text('Điều chỉnh giá vốn không chia xuống từng đơn.'),
        findsOneWidget,
      );
      await tester.tap(find.text('DH-0001'));
      await tester.pumpAndSettle();
      expect(opened, 'o1');
    });

    testWidgets('gross_profit_empty', (tester) async {
      repo.grossProductResult = grossProductOf(rows: const [], loss: 0);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Chưa có đơn bán trong kỳ'), findsOneWidget);
      expect(find.text('Đổi khoảng ngày để xem dữ liệu khác.'), findsOneWidget);
    });

    testWidgets('gross_profit_denied_390', (tester) async {
      repo.error = const AppException(InventoryErrorCode.permissionDenied);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa có quyền xem lãi gộp'), findsOneWidget);
      expect(find.text('Chỉ chủ cửa hàng xem báo cáo lãi gộp.'), findsOneWidget);
      expect(find.text('Về Kho'), findsOneWidget);
      expect(findMoneyText(), findsNothing);
    });
  });
}
