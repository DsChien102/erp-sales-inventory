import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_recount_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeRecountRepository extends Fake implements StocktakeRepository {
  StocktakeSession session = StocktakeSession(
    id: 's1',
    code: 'KK-260917-01',
    scopeKind: StocktakeScopeKind.all,
    scopeLabel: 'Toàn kho',
    counterName: 'Nguyễn Văn An',
    reason: 'Kiểm kê định kỳ',
    status: StocktakeStatus.recount,
    openedAt: DateTime(2026, 9, 17, 18, 30),
    lines: const [
      StocktakeLine(
        lineId: 'l-oxy',
        productId: 'p1',
        productName: 'Oxytetracycline LA',
        productCode: 'SP-000147',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: true,
        bookQty: 12,
        firstQty: 10,
        variance: -2,
      ),
      StocktakeLine(
        lineId: 'l-ty2511',
        productId: 'p2',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        lotId: 'lot1',
        lotCode: 'TY2511',
        isExpired: false,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: true,
        bookQty: 3,
        firstQty: 4,
        variance: 1,
      ),
      StocktakeLine(
        lineId: 'l-ty2408',
        productId: 'p2',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        lotId: 'lot2',
        lotCode: 'TY2408',
        isExpired: true,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: false,
        bookQty: 5,
        firstQty: 5,
        variance: 0,
      ),
    ],
  );

  List<StocktakeCountInput>? submittedCounts;
  String? lastCancelReason;
  Object? nextSubmitError;

  @override
  Future<StocktakeSession> get(String sessionId) async => session;

  @override
  Future<StocktakeSubmitResult> submitRecount({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    if (nextSubmitError != null) throw nextSubmitError!;
    submittedCounts = List<StocktakeCountInput>.from(counts);
    return const StocktakeSubmitResult(
      status: StocktakeStatus.completed,
      resultKind: StocktakeResultKind.adjusted,
    );
  }

  @override
  Future<StocktakeStatus> cancel({
    required String idempotencyKey,
    required String sessionId,
    required String reason,
  }) async {
    lastCancelReason = reason;
    return StocktakeStatus.cancelled;
  }
}

void main() {
  group('StocktakeRecountPage', () {
    late _FakeRecountRepository repository;
    String? navId;
    StocktakeStatus? navStatus;
    var backToListCalls = 0;

    setUp(() async {
      await GetIt.I.reset();
      repository = _FakeRecountRepository();
      GetIt.I.registerSingleton<StocktakeRepository>(repository);
      navId = null;
      navStatus = null;
      backToListCalls = 0;
    });

    tearDown(() async {
      await GetIt.I.reset();
    });

    Widget buildApp({Size size = const Size(390, 844)}) {
      useInventoryTestSurface(size);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: child!,
        ),
        home: StocktakeRecountPage(
          sessionId: 's1',
          onNavigate: (id, status) {
            navId = id;
            navStatus = status;
          },
          onBackToList: () => backToListCalls++,
        ),
      );
    }

    testWidgets(
      'recount_ready renders summary strip, variance rows, and matched sheet on 390',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Chênh lệch và đếm lại'), findsOneWidget);
        expect(find.text('KK-260917-01 · Đếm lại lần 1'), findsOneWidget);
        expect(find.text('Mặt hàng lệch'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Khớp'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        expect(find.text('Thiếu 2 chai'), findsOneWidget);
        expect(find.text('Thừa 1 lọ'), findsOneWidget);
        expect(find.text('Theo sổ 12 chai · Đếm đầu 10 chai'), findsOneWidget);
        expect(find.text('Vẫn 10 chai'), findsOneWidget);
        expect(find.text('Xem 1 mặt hàng khớp'), findsOneWidget);

        await tester.tap(find.text('Xem 1 mặt hàng khớp'));
        await tester.pumpAndSettle();

        expect(find.text('Mặt hàng khớp'), findsOneWidget);
        expect(find.text('Tylosin 20% · Lô TY2408'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Đóng'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'recount_ready renders 7 web columns including Lý do and Đếm lại on 1280',
      (tester) async {
        await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
        await tester.pumpAndSettle();

        expect(find.text('SẢN PHẨM'), findsOneWidget);
        expect(find.text('LÔ'), findsOneWidget);
        expect(find.text('THEO SỔ'), findsOneWidget);
        expect(find.text('ĐẾM ĐẦU'), findsOneWidget);
        expect(find.text('CHÊNH LỆCH'), findsOneWidget);
        expect(find.text('LÝ DO'), findsOneWidget);
        expect(find.text('ĐẾM LẠI'), findsOneWidget);
        expect(find.text('Thiếu 2 chai'), findsOneWidget);
        expect(find.text('Thừa 1 lọ'), findsOneWidget);
        expect(find.text('Vẫn 10 chai'), findsOneWidget);
        expect(find.text('Xem 1 mặt hàng khớp'), findsOneWidget);

        final buttonRect = tester.getRect(
          find.widgetWithText(VButton, 'Vẫn 10 chai'),
        );
        expect(buttonRect.left, greaterThanOrEqualTo(0));
        expect(buttonRect.right, lessThanOrEqualTo(1280));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'recount_reason_only_short shows segmented reason only for short lines with expired default',
      (tester) async {
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-01',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.recount,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          lines: const [
            StocktakeLine(
              lineId: 'l-oxy',
              productId: 'p1',
              productName: 'Oxytetracycline LA',
              productCode: 'SP-000147',
              isExpired: false,
              uom: 'chai',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 12,
              firstQty: 10,
              variance: -2,
            ),
            StocktakeLine(
              lineId: 'l-ty2511',
              productId: 'p2',
              productName: 'Tylosin 20%',
              productCode: 'SP-000122',
              lotId: 'lot1',
              lotCode: 'TY2511',
              isExpired: false,
              uom: 'lọ',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 3,
              firstQty: 4,
              variance: 1,
            ),
            StocktakeLine(
              lineId: 'l-ty2408',
              productId: 'p2',
              productName: 'Tylosin 20%',
              productCode: 'SP-000122',
              lotId: 'lot2',
              lotCode: 'TY2408',
              isExpired: true,
              uom: 'lọ',
              isUnexpected: false,
              needsRecount: true,
              bookQty: 5,
              firstQty: 2,
              variance: -3,
            ),
          ],
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final controls = tester
            .widgetList<VSegmentedControl>(find.byType(VSegmentedControl))
            .toList();
        expect(controls, hasLength(2));
        expect(controls[0].selectedIndex, StocktakeLossReason.loss.index);
        expect(controls[1].selectedIndex, StocktakeLossReason.expired.index);
      },
    );

    testWidgets(
      'recount_same_button fills firstQty into cell and updates remaining count',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Còn 2 mặt hàng chưa đếm lại'), findsOneWidget);

        await tester.tap(find.widgetWithText(VButton, 'Vẫn 10 chai'));
        await tester.pump();

        final oxyCell = tester.widget<K7EditCell>(
          find.byType(K7EditCell).first,
        );
        expect(oxyCell.value, '10');
        expect(find.text('Còn 1 mặt hàng chưa đếm lại'), findsOneWidget);
      },
    );

    testWidgets(
      'recount_submit sends counts and updated loss reason through confirm sheet',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(VButton, 'Vẫn 10 chai'));
        await tester.pump();
        await tester.tap(find.widgetWithText(VButton, 'Vẫn 4 lọ'));
        await tester.pump();

        // Đổi lý do Oxy từ Thất thoát sang Hỏng
        await tester.tap(find.text('Hỏng'));
        await tester.pump();

        await tester.tap(find.widgetWithText(VButton, 'Ghi nhận điều chỉnh'));
        await tester.pumpAndSettle();

        expect(find.text('Ghi nhận điều chỉnh?'), findsOneWidget);
        expect(
          find.text(
            'Kết quả đếm lại được lưu, không sửa được. Dòng còn lệch được điều chỉnh vào tồn kho theo số đếm.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(VButton, 'Ghi nhận'));
        await tester.pumpAndSettle();

        expect(repository.submittedCounts, [
          const StocktakeCountInput(
            lineId: 'l-oxy',
            quantity: 10,
            lossReason: StocktakeLossReason.damaged,
          ),
          const StocktakeCountInput(
            lineId: 'l-ty2511',
            quantity: 4,
          ),
        ]);
        expect(navId, 's1');
        expect(navStatus, StocktakeStatus.completed);
      },
    );

    testWidgets(
      'recount_state_changed shows stale lockLost view when session cancelled concurrently',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(VButton, 'Vẫn 10 chai'));
        await tester.pump();
        await tester.tap(find.widgetWithText(VButton, 'Vẫn 4 lọ'));
        await tester.pump();

        repository.nextSubmitError = const AppException(
          InventoryErrorCode.stocktakeStateChanged,
          serverMessage: 'state changed',
        );
        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-260917-01',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.cancelled,
          openedAt: DateTime(2026, 9, 17, 18, 30),
          lines: const [],
        );

        await tester.tap(find.widgetWithText(VButton, 'Ghi nhận điều chỉnh'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Ghi nhận'));
        await tester.pumpAndSettle();

        expect(find.text('Phiên không còn hiệu lực'), findsOneWidget);
        await tester.tap(find.widgetWithText(VButton, 'Về kiểm kê'));
        await tester.pump();
        expect(backToListCalls, 1);
      },
    );
  });
}
