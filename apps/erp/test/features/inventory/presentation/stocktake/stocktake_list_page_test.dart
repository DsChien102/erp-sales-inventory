import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeStocktakeRepository extends Fake implements StocktakeRepository {
  List<StocktakeListRow> rows = const [];

  @override
  Future<List<StocktakeListRow>> list() async => rows;
}

void main() {
  late _FakeStocktakeRepository repository;

  final countingRow = StocktakeListRow(
    id: 's1',
    code: 'KK-261112-01',
    scopeLabel: 'Toàn kho',
    counterName: 'Nguyễn Văn An',
    status: StocktakeStatus.counting,
    openedAt: DateTime(2026, 11, 12, 18, 30),
    lineCount: 9,
    countedCount: 4,
    varianceCount: 0,
  );

  final recountRow = StocktakeListRow(
    id: 's2',
    code: 'KK-261112-02',
    scopeLabel: 'Oxytetracycline',
    counterName: 'Trần Thị Bình',
    status: StocktakeStatus.recount,
    openedAt: DateTime(2026, 11, 12, 16, 15),
    lineCount: 5,
    countedCount: 5,
    varianceCount: 1,
  );

  final completedRow = StocktakeListRow(
    id: 's3',
    code: 'KK-261110-01',
    scopeLabel: 'Toàn kho',
    counterName: 'Chủ cửa hàng',
    status: StocktakeStatus.completed,
    openedAt: DateTime(2026, 11, 10, 18, 0),
    lineCount: 9,
    countedCount: 9,
    varianceCount: 0,
  );

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeStocktakeRepository()
      ..rows = [countingRow, recountRow, completedRow];
    GetIt.I.registerSingleton<StocktakeRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    ValueChanged<StocktakeListRow>? onOpen,
    VoidCallback? onCreate,
  }) {
    useInventoryTestSurface(size);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
      home: StocktakeListPage(
        onOpen: onOpen ?? (_) {},
        onCreate: onCreate ?? () {},
      ),
    );
  }

  group('StocktakeListPage', () {
    testWidgets('list_ready renders 390 mobile layout and opens tapped row', (
      tester,
    ) async {
      StocktakeListRow? opened;
      await tester.pumpWidget(buildApp(onOpen: (r) => opened = r));
      await tester.pumpAndSettle();

      expect(find.text('Kiểm kê kho'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text(' 3'), findsOneWidget);
      expect(find.text('Đang đếm'), findsWidgets);
      expect(find.text('Đếm lại'), findsWidgets);
      expect(find.text('Đã xong'), findsWidgets);
      expect(find.text(' 1'), findsNWidgets(3));
      expect(
        find.text('Toàn kho · Nguyễn Văn An · Đã đếm 4/9'),
        findsOneWidget,
      );

      await tester.tap(find.text('KK-261112-02'));
      await tester.pumpAndSettle();

      expect(opened, recountRow);
    });

    testWidgets('list_ready renders 1280 web table with Mở lúc column', (
      tester,
    ) async {
      StocktakeListRow? opened;
      await tester.pumpWidget(
        buildApp(
          size: const Size(1280, 800),
          onOpen: (r) => opened = r,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PHIÊN'), findsOneWidget);
      expect(find.text('PHẠM VI'), findsOneWidget);
      expect(find.text('NGƯỜI ĐẾM'), findsOneWidget);
      expect(find.text('ĐÃ ĐẾM'), findsOneWidget);
      expect(find.text('MỞ LÚC'), findsOneWidget);
      expect(find.text('TÌNH TRẠNG'), findsOneWidget);
      expect(find.text('4/9'), findsOneWidget);
      expect(find.text('1 lệch'), findsOneWidget);

      await tester.tap(find.text('KK-261112-02'));
      await tester.pumpAndSettle();

      expect(opened, recountRow);
    });

    testWidgets('list_empty shows empty copy and create button', (
      tester,
    ) async {
      repository.rows = const [];
      var created = false;
      await tester.pumpWidget(buildApp(onCreate: () => created = true));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có phiên kiểm kê'), findsOneWidget);
      expect(
        find.text('Tạo phiên để đếm toàn kho hoặc một nhóm hàng.'),
        findsOneWidget,
      );
      expect(find.text('Tạo phiên kiểm kê'), findsOneWidget);

      await tester.tap(find.text('Tạo phiên kiểm kê'));
      await tester.pumpAndSettle();

      expect(created, isTrue);
    });

    testWidgets('list_filter_empty shows empty filter and Xem tất cả resets', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VSearchBar), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy phiên kiểm kê'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);

      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();

      expect(find.text('KK-261112-01'), findsOneWidget);
      expect(find.text('KK-261112-02'), findsOneWidget);
    });
  });
}
