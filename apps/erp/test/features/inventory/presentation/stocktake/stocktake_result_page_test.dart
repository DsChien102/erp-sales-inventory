import 'package:erp/features/inventory/data/core/inventory_command_result.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeResultRepository extends Fake implements StocktakeRepository {
  late StocktakeSession session;

  @override
  Future<StocktakeSession> get(String sessionId) async => session;
}

void main() {
  group('StocktakeResultPage', () {
    late _FakeResultRepository repository;
    var backToListCalls = 0;
    var viewStockCalls = 0;

    setUp(() async {
      await GetIt.I.reset();
      repository = _FakeResultRepository();
      GetIt.I.registerSingleton<StocktakeRepository>(repository);
      backToListCalls = 0;
      viewStockCalls = 0;
    });

    tearDown(() async {
      await GetIt.I.reset();
    });

    Widget buildApp() {
      const size = Size(390, 844);
      useInventoryTestSurface(size);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: child!,
        ),
        home: StocktakeResultPage(
          sessionId: 's1',
          onBackToList: () => backToListCalls++,
          onViewStock: () => viewStockCalls++,
        ),
      );
    }

    testWidgets(
      'result_adjusted_owner shows adjusted count, signed value, stockChanges, and approver',
      (tester) async {
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-01',
          scopeKind: StocktakeScopeKind.product,
          scopeLabel: 'Thuốc kháng sinh',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.completed,
          resultKind: StocktakeResultKind.adjusted,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          completedAt: DateTime(2026, 9, 17, 20, 10),
          completedByName: 'Chủ cửa hàng',
          adjustmentValueVnd: -110000,
          stockChanges: const [
            InventoryStockChange(
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              baseUom: 'chai',
              before: 12,
              after: 10,
            ),
          ],
          lines: const [
            StocktakeLine(
              lineId: 'l1',
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              productCode: 'SP-000147',
              isExpired: false,
              uom: 'chai',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 12,
              firstQty: 10,
              recountQty: 10,
              adjustQty: -2,
            ),
            StocktakeLine(
              lineId: 'l2',
              productId: 'p2',
              productName: 'Tylosin 20%',
              productCode: 'SP-000122',
              isExpired: false,
              uom: 'lọ',
              isUnexpected: false,
              needsRecount: false,
              bookQty: 5,
              firstQty: 5,
              adjustQty: 0,
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Đã hoàn tất kiểm kê'), findsOneWidget);
        expect(
          find.text('Điều chỉnh chênh lệch đã được ghi vào tồn kho.'),
          findsOneWidget,
        );
        expect(find.text('Đã điều chỉnh'), findsOneWidget);
        expect(find.text('1 dòng'), findsOneWidget);
        expect(find.text('Thiếu 1 · thừa 0 mặt hàng'), findsOneWidget);
        expect(find.text('Giá trị điều chỉnh'), findsOneWidget);
        expect(find.text('-110.000đ'), findsOneWidget);
        expect(find.text('Tồn kho đã đổi'), findsOneWidget);
        expect(find.text('Oxytetracycline LA 12 chai → 10 chai'), findsOneWidget);
        expect(find.text('Người ghi nhận'), findsOneWidget);
        expect(find.text('Chủ cửa hàng'), findsOneWidget);

        final viewStockBtn = find.widgetWithText(VButton, 'Xem tồn kho');
        await tester.ensureVisible(viewStockBtn);
        await tester.tap(viewStockBtn);
        await tester.pump();
        expect(viewStockCalls, 1);

        final backBtn = find.widgetWithText(VButton, 'Về kiểm kê');
        await tester.ensureVisible(backBtn);
        await tester.tap(backBtn);
        await tester.pump();
        expect(backToListCalls, 1);
      },
    );

    testWidgets(
      'result_adjusted_staff hides Giá trị điều chỉnh when adjustment_value_vnd is null',
      (tester) async {
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-01',
          scopeKind: StocktakeScopeKind.product,
          scopeLabel: 'Thuốc kháng sinh',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.completed,
          resultKind: StocktakeResultKind.adjusted,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          completedAt: DateTime(2026, 9, 17, 20, 10),
          completedByName: 'Nhân viên kho',
          stockChanges: const [
            InventoryStockChange(
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              baseUom: 'chai',
              before: 12,
              after: 10,
            ),
          ],
          lines: const [
            StocktakeLine(
              lineId: 'l1',
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              productCode: 'SP-000147',
              isExpired: false,
              uom: 'chai',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 12,
              firstQty: 10,
              recountQty: 10,
              adjustQty: -2,
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Đã hoàn tất kiểm kê'), findsOneWidget);
        expect(find.text('Giá trị điều chỉnh'), findsNothing);
        expect(find.text('Đã điều chỉnh'), findsOneWidget);
        expect(find.text('1 dòng'), findsOneWidget);
        expect(find.text('Tồn kho đã đổi'), findsOneWidget);
      },
    );

    testWidgets(
      'result_matched displays matched description and completed timestamp',
      (tester) async {
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-02',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.completed,
          resultKind: StocktakeResultKind.matched,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          completedAt: DateTime(2026, 9, 17, 20, 10),
          lines: const [],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Đã hoàn tất kiểm kê'), findsOneWidget);
        expect(
          find.text('Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh.'),
          findsOneWidget,
        );
        expect(find.text('Hoàn tất lúc'), findsOneWidget);
        expect(find.text('17/09/2026 20:10'), findsOneWidget);
        expect(find.widgetWithText(VButton, 'Về kiểm kê'), findsOneWidget);
        expect(find.widgetWithText(VButton, 'Xem tồn kho'), findsOneWidget);
      },
    );

    testWidgets(
      'result_cancelled shows warning result with reason and only Về kiểm kê action',
      (tester) async {
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-03',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.cancelled,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          cancelledAt: DateTime(2026, 9, 17, 20, 15),
          cancelReason: 'Đóng ca kiểm kê',
          lines: const [],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Đã hủy phiên'), findsOneWidget);
        expect(
          find.text('Không tạo điều chỉnh. Lịch sử đếm được giữ.'),
          findsOneWidget,
        );
        expect(find.text('Lý do'), findsOneWidget);
        expect(find.text('Đóng ca kiểm kê'), findsOneWidget);
        expect(find.widgetWithText(VButton, 'Về kiểm kê'), findsOneWidget);
        expect(find.widgetWithText(VButton, 'Xem tồn kho'), findsNothing);
      },
    );
  });
}
