import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_count_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeCountRepository extends Fake implements StocktakeRepository {
  StocktakeSession session = StocktakeSession(
    id: 's1',
    code: 'KK-261112-01',
    scopeKind: StocktakeScopeKind.all,
    scopeLabel: 'Toàn kho',
    counterName: 'Nguyễn Văn An',
    reason: 'Kiểm kê định kỳ',
    status: StocktakeStatus.counting,
    openedAt: DateTime(2026, 11, 12, 18, 30),
    lines: const [
      StocktakeLine(
        lineId: 'l1',
        productId: 'p1',
        productName: 'Oxytetracycline LA',
        productCode: 'SP-000147',
        isExpired: false,
        uom: 'chai',
        isUnexpected: false,
        needsRecount: false,
      ),
      StocktakeLine(
        lineId: 'l2',
        productId: 'p2',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        lotId: 'lot1',
        lotCode: 'TY2511',
        isExpired: false,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: false,
      ),
      StocktakeLine(
        lineId: 'l3',
        productId: 'p2',
        productName: 'Tylosin 20%',
        productCode: 'SP-000122',
        lotId: 'lot2',
        lotCode: 'TY2408',
        isExpired: true,
        uom: 'lọ',
        isUnexpected: false,
        needsRecount: false,
      ),
    ],
  );

  // Giả lập sổ kho trên server (không bao giờ trả về JSON blind get())
  final serverBookQty = const {'l1': 17, 'l2': 23, 'l3': 29};

  StocktakeUnexpectedOptions nextUnexpectedOptions =
      const StocktakeUnexpectedOptions(
        products: [
          StocktakeUnexpectedProduct(
            id: 'p9',
            name: 'Găng tay khám Nitrile',
            code: 'GLV-01',
            uom: 'hộp',
            trackingMode: 'none',
            lots: [],
          ),
        ],
      );

  StocktakeLine addedUnexpectedLine = const StocktakeLine(
    lineId: 'l9',
    productId: 'p9',
    productName: 'Găng tay khám Nitrile',
    productCode: 'GLV-01',
    isExpired: false,
    uom: 'hộp',
    isUnexpected: true,
    needsRecount: false,
  );

  StocktakeSubmitResult nextSubmitResult = const StocktakeSubmitResult(
    status: StocktakeStatus.recount,
  );
  Object? nextSubmitError;
  StocktakeStatus nextCancelStatus = StocktakeStatus.cancelled;
  int submitCalls = 0;
  List<StocktakeCountInput>? lastCounts;
  String? lastCancelReason;

  @override
  Future<StocktakeSession> get(String sessionId) async => session;

  @override
  Future<void> saveDraft({
    required String sessionId,
    required String lineId,
    num? quantity,
  }) async {}

  @override
  Future<StocktakeUnexpectedOptions> unexpectedOptions(String sessionId) async =>
      nextUnexpectedOptions;

  @override
  Future<StocktakeLine> addUnexpected({
    required String sessionId,
    required String productId,
    String? lotId,
    String? lotCode,
    DateTime? expiryDate,
    String? expiryPrecision,
  }) async => addedUnexpectedLine;

  @override
  Future<StocktakeSubmitResult> submitFirst({
    required String idempotencyKey,
    required String sessionId,
    required List<StocktakeCountInput> counts,
  }) async {
    submitCalls++;
    lastCounts = counts;
    if (nextSubmitError != null) {
      final err = nextSubmitError!;
      nextSubmitError = null;
      throw err;
    }
    return nextSubmitResult;
  }

  @override
  Future<StocktakeStatus> cancel({
    required String idempotencyKey,
    required String sessionId,
    required String reason,
  }) async {
    lastCancelReason = reason;
    return nextCancelStatus;
  }
}

void main() {
  late _FakeCountRepository repository;

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeCountRepository();
    GetIt.I.registerSingleton<StocktakeRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    void Function(String id, StocktakeStatus s)? onNavigate,
    VoidCallback? onBackToList,
  }) {
    useInventoryTestSurface(size);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
      home: StocktakeCountPage(
        sessionId: 's1',
        onNavigate: onNavigate ?? (_, _) {},
        onBackToList: onBackToList ?? () {},
      ),
    );
  }

  group('StocktakeCountPage', () {
    testWidgets(
      'count_page_has_no_book_qty hides book qty and shows blind header & todo 3',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(repository.serverBookQty['l1'], 17);
        expect(find.textContaining('17'), findsNothing);
        expect(find.textContaining('23'), findsNothing);
        expect(find.textContaining('29'), findsNothing);
        expect(find.textContaining('Theo sổ'), findsNothing);
        expect(
          find.text('Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.'),
          findsOneWidget,
        );
        expect(find.text('Đã đếm 0/3 mặt hàng'), findsOneWidget);
        expect(find.text('Chưa đếm'), findsOneWidget);
        expect(find.text(' 3'), findsWidgets);
      },
    );

    testWidgets(
      'count_progress updates progress/chips/footer and Enter focuses next uncounted field',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        // fields[0] is VSearchBar, fields[1..3] are line K7EditCells
        await tester.tap(fields.at(1));
        await tester.enterText(fields.at(1), '10');
        await tester.pump();

        expect(find.text('Đã đếm 1/3 mặt hàng'), findsOneWidget);
        expect(find.text(' 1'), findsOneWidget); // chip Đã đếm 1
        expect(find.text('Còn 2 mặt hàng chưa đếm'), findsOneWidget);

        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();

        final nextTf = tester.widget<TextField>(fields.at(2));
        expect(nextTf.focusNode?.hasFocus, isTrue);
      },
    );

    testWidgets('count_submit_recount submits once and navigates to recount', (
      tester,
    ) async {
      String? navId;
      StocktakeStatus? navStatus;
      await tester.pumpWidget(
        buildApp(
          onNavigate: (id, status) {
            navId = id;
            navStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '12');
      await tester.enterText(fields.at(2), '2');
      await tester.enterText(fields.at(3), '11');
      await tester.pump();

      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả đếm'));
      await tester.pumpAndSettle();

      expect(find.text('Nộp lần đếm đầu?'), findsOneWidget);
      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả'));
      await tester.pumpAndSettle();

      expect(repository.submitCalls, 1);
      expect(navId, 's1');
      expect(navStatus, StocktakeStatus.recount);
    });

    testWidgets('count_submit_matched navigates to completed', (tester) async {
      repository.nextSubmitResult = const StocktakeSubmitResult(
        status: StocktakeStatus.completed,
        resultKind: StocktakeResultKind.matched,
      );
      StocktakeStatus? navStatus;
      await tester.pumpWidget(
        buildApp(onNavigate: (_, status) => navStatus = status),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '12');
      await tester.enterText(fields.at(2), '3');
      await tester.enterText(fields.at(3), '11');
      await tester.pump();

      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả đếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả'));
      await tester.pumpAndSettle();

      expect(navStatus, StocktakeStatus.completed);
    });

    testWidgets(
      'count_state_changed handles reloaded CANCELLED vs RECOUNT appropriately',
      (tester) async {
        // Case 1: reloaded CANCELLED -> Phiên không còn hiệu lực
        repository.nextSubmitError = const AppException(
          InventoryErrorCode.stocktakeStateChanged,
        );
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(1), '12');
        await tester.enterText(fields.at(2), '2');
        await tester.enterText(fields.at(3), '11');
        await tester.pump();

        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-261112-01',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.cancelled,
          openedAt: DateTime(2026, 11, 12, 18, 30),
          lines: const [],
        );

        await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả đếm'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả'));
        await tester.pumpAndSettle();

        expect(find.text('Phiên không còn hiệu lực'), findsOneWidget);
        expect(
          find.text('Phiên đã bị hủy. Số đã đếm vẫn được lưu.'),
          findsOneWidget,
        );

        // Case 2: reloaded RECOUNT -> Người khác vừa nộp phiên này + Tải lại
        await tester.pumpWidget(const SizedBox.shrink());
        repository = _FakeCountRepository();
        GetIt.I.unregister<StocktakeRepository>();
        GetIt.I.registerSingleton<StocktakeRepository>(repository);
        repository.nextSubmitError = const AppException(
          InventoryErrorCode.stocktakeStateChanged,
        );

        StocktakeStatus? navStatus;
        await tester.pumpWidget(
          buildApp(onNavigate: (_, status) => navStatus = status),
        );
        await tester.pumpAndSettle();

        final fields2 = find.byType(TextField);
        await tester.enterText(fields2.at(1), '12');
        await tester.enterText(fields2.at(2), '2');
        await tester.enterText(fields2.at(3), '11');
        await tester.pump();

        repository.session = StocktakeSession(
          id: 's1',
          code: 'KK-261112-01',
          scopeKind: StocktakeScopeKind.all,
          scopeLabel: 'Toàn kho',
          counterName: 'Nguyễn Văn An',
          reason: 'Kiểm kê định kỳ',
          status: StocktakeStatus.recount,
          openedAt: DateTime(2026, 11, 12, 18, 30),
          lines: const [],
        );

        await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả đếm'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Nộp kết quả'));
        await tester.pumpAndSettle();

        expect(find.text('Người khác vừa nộp phiên này'), findsOneWidget);
        expect(find.text('Tải lại'), findsOneWidget);

        await tester.tap(find.text('Tải lại'));
        await tester.pumpAndSettle();
        expect(navStatus, StocktakeStatus.recount);
      },
    );

    testWidgets(
      'count_cancel requires reason in sheet and navigates to cancelled',
      (tester) async {
        StocktakeStatus? navStatus;
        await tester.pumpWidget(
          buildApp(onNavigate: (_, status) => navStatus = status),
        );
        await tester.pumpAndSettle();

        final cancelBtn = find.widgetWithText(VButton, 'Hủy phiên');
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        expect(find.text('Hủy phiên kiểm kê?'), findsOneWidget);
        expect(
          find.text('Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ.'),
          findsOneWidget,
        );

        // Confirm button disabled when reason empty
        final confirmBtnFinder = find.widgetWithText(VButton, 'Hủy phiên').last;
        expect(tester.widget<VButton>(confirmBtnFinder).onPressed, isNull);

        await tester.enterText(find.byType(VTextField).last, 'Đóng ca kiểm kê');
        await tester.pump();

        expect(tester.widget<VButton>(confirmBtnFinder).onPressed, isNotNull);
        await tester.tap(confirmBtnFinder);
        await tester.pumpAndSettle();

        expect(repository.lastCancelReason, 'Đóng ca kiểm kê');
        expect(navStatus, StocktakeStatus.cancelled);
      },
    );

    testWidgets(
      'count_unexpected picks non-lot product and displays Hàng thực tế badge',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(VButton, 'Thêm hàng thực tế'));
        await tester.pumpAndSettle();

        expect(find.text('Găng tay khám Nitrile'), findsOneWidget);
        await tester.tap(find.text('Găng tay khám Nitrile'));
        await tester.pumpAndSettle();

        expect(find.text('Hàng thực tế'), findsOneWidget);
        expect(find.text('Găng tay khám Nitrile'), findsOneWidget);
      },
    );

    testWidgets(
      'count_web_table renders 4 web columns and shows Hết hạn for TY2408',
      (tester) async {
        await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
        await tester.pumpAndSettle();

        expect(find.text('SẢN PHẨM'), findsOneWidget);
        expect(find.text('LÔ'), findsOneWidget);
        expect(find.text('TÌNH TRẠNG'), findsOneWidget);
        expect(find.text('ĐẾM ĐƯỢC'), findsOneWidget);
        expect(find.text('Hết hạn'), findsOneWidget);
        expect(find.text('Bán được'), findsNWidgets(2));
      },
    );
  });
}
