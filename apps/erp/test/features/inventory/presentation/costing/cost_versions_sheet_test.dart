import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/presentation/costing/cost_versions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeCostingRepository extends Fake implements CostingRepository {
  CostVersionList? versionsResult;

  @override
  Future<CostVersionList> versions(String productId) async => versionsResult!;
}

void main() {
  late _FakeCostingRepository repository;

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeCostingRepository();
    GetIt.I.registerSingleton<CostingRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<void> openSheet(WidgetTester tester) async {
    useInventoryTestSurface(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCostVersionsSheet(
                  context,
                  productId: 'p1',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('CostVersionsSheet', () {
    testWidgets('versions_sheet_rows renders formatted cost and publish meta',
        (tester) async {
      repository.versionsResult = CostVersionList(
        productId: 'p1',
        name: 'Amox 500',
        uom: 'hộp',
        versions: [
          CostVersion(
            versionId: 'v1',
            unitCost: 11000,
            method: CostMethod.periodic,
            runCode: 'GV-2611-01',
            publishedAt: DateTime(2026, 11, 3, 9, 0),
          ),
        ],
      );

      await openSheet(tester);

      expect(find.text('Lịch sử giá vốn'), findsOneWidget);
      expect(find.text('11.000 đ/hộp'), findsOneWidget);
      expect(
        find.text('Bình quân cuối kỳ · Công bố 03/11/2026 · GV-2611-01'),
        findsOneWidget,
      );
      expect(find.text('Đóng'), findsOneWidget);
    });

    testWidgets('versions_sheet_empty renders empty message', (tester) async {
      repository.versionsResult = const CostVersionList(
        productId: 'p1',
        name: 'Amox 500',
        uom: 'hộp',
        versions: [],
      );

      await openSheet(tester);

      expect(find.text('Chưa có giá vốn chính thức'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);
    });
  });
}

