import 'dart:io';

import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/reports/gross_profit_page.dart';
import 'package:erp/features/inventory/presentation/reports/movement_detail_page.dart';
import 'package:erp/features/inventory/presentation/reports/stock_card_page.dart';
import 'package:erp/features/inventory/presentation/reports/stock_report_page.dart';
import 'package:erp/features/inventory/presentation/reports/supplier_purchase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';
import 'reports_test_support.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-7/$fileName';
}

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository()
      ..stockReportResult = stockReportOf([
        stockRow(),
        stockRow(
          id: 'p2',
          name: 'Amoxicillin 500mg',
          code: 'AM-500',
          opening: 40,
          inQty: 0,
          outQty: 8,
          closing: 32,
          available: 32,
          value: 1600000,
        ),
      ])
      ..stockCardResult = stockCardOf()
      ..movementResult = movementDetailOf()
      ..grossProductResult = grossProductOf()
      ..grossOrderResult = grossOrderOf()
      ..supplierResult = supplierReportOf();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<void> capture(
    WidgetTester tester, {
    required Widget page,
    required String name,
  }) async {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      useInventoryTestSurface(size);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: VTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: child!,
          ),
          home: RepaintBoundary(key: key, child: page),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(_goldenPath('flutter-$name-${size.width.toInt()}.png')),
      );
    }
  }

  group('Reports golden screenshots (G5-7 Task 7)', () {
    testWidgets('055_READY', (tester) async {
      await capture(
        tester,
        page: StockReportPage(clock: () => reportsToday),
        name: '055-READY',
      );
    });

    testWidgets('055_FINANCIAL_RESTRICTED', (tester) async {
      repo.stockReportResult = stockReportOf(
        [stockRow(value: null)],
        masked: true,
      );
      await capture(
        tester,
        page: StockReportPage(clock: () => reportsToday),
        name: '055-FINANCIAL_RESTRICTED',
      );
    });

    testWidgets('055_EMPTY', (tester) async {
      repo.stockReportResult = stockReportOf(const []);
      await capture(
        tester,
        page: StockReportPage(clock: () => reportsToday),
        name: '055-EMPTY',
      );
    });

    testWidgets('055_CARD_LOTS', (tester) async {
      await capture(
        tester,
        page: StockCardPage(productId: 'p1', clock: () => reportsToday),
        name: '055-CARD-LOTS',
      );
    });

    testWidgets('056_READY', (tester) async {
      await capture(
        tester,
        page: const MovementDetailPage(movementId: 'm1'),
        name: '056-READY',
      );
    });

    testWidgets('GROSS_PROFIT_PRODUCT', (tester) async {
      await capture(
        tester,
        page: GrossProfitPage(clock: () => reportsToday),
        name: 'GROSS-PROFIT-PRODUCT',
      );
    });

    testWidgets('SUPPLIER_PURCHASES', (tester) async {
      await capture(
        tester,
        page: SupplierPurchasePage(clock: () => reportsToday),
        name: 'SUPPLIER-PURCHASES',
      );
    });
  });
}
