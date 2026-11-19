import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:c45_design_system/design_system.dart';

class MockStockPolicyRepository extends Mock implements StockPolicyRepository {}

void main() {
  late MockStockPolicyRepository mockRepo;

  final sampleProducts = [
    const StockPolicyProduct(
      productId: 'p_nobivac',
      name: 'Nobivac DHPPi',
      code: 'NOBI',
      uom: 'hộp',
      isLotTracked: true,
      available: 30,
      hasExpired: false,
      hasNearExpiry: false,
      threshold: 30,
      target: 80,
    ),
    const StockPolicyProduct(
      productId: 'p_amox',
      name: 'Amoxicillin 500',
      code: 'AMOX',
      uom: 'vỉ',
      isLotTracked: false,
      available: 120,
      hasExpired: false,
      hasNearExpiry: false,
      threshold: 50,
      target: 80,
    ),
    const StockPolicyProduct(
      productId: 'p_enro',
      name: 'Enrofloxacin 10%',
      code: 'ENRO',
      uom: 'chai',
      isLotTracked: true,
      available: 0,
      hasExpired: false,
      hasNearExpiry: false,
      threshold: 10,
      target: 30,
    ),
    const StockPolicyProduct(
      productId: 'p_tylo',
      name: 'Tylosin 200',
      code: 'TYLO',
      uom: 'lọ',
      isLotTracked: true,
      available: 24,
      hasExpired: true,
      hasNearExpiry: false,
      threshold: 8,
      target: 24,
    ),
    const StockPolicyProduct(
      productId: 'p_oxy',
      name: 'Oxytetracycline LA',
      code: 'OXY',
      uom: 'chai',
      isLotTracked: true,
      available: 25,
      hasExpired: false,
      hasNearExpiry: false,
      threshold: null,
      target: null,
    ),
  ];

  StockPolicySnapshot defaultSnapshot({bool isOwner = true}) {
    return StockPolicySnapshot(
      revision: 5,
      isOwner: isOwner,
      nearExpiryDays: null,
      products: sampleProducts,
    );
  }

  setUp(() {
    mockRepo = MockStockPolicyRepository();
    if (getIt.isRegistered<StockPolicyRepository>()) {
      getIt.unregister<StockPolicyRepository>();
    }
    getIt.registerSingleton<StockPolicyRepository>(mockRepo);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildScreen({
    Size size = const Size(1280, 800),
    String? initialTab,
    Key? key,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: StockPolicyPage(
          key: key ?? UniqueKey(),
          initialTab: initialTab,
        ),
      ),
    );
  }

  group('StockPolicyPage UI', () {
    testWidgets('table_ready_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Chính sách tồn & cận hạn'), findsOneWidget);
      expect(find.text('SẢN PHẨM'), findsOneWidget);
      expect(find.text('ĐVT'), findsOneWidget);
      expect(find.text('KHẢ DỤNG'), findsOneWidget);
      expect(find.text('NGƯỠNG CẢNH BÁO'), findsOneWidget);
      expect(find.text('MỨC TỒN MỤC TIÊU'), findsOneWidget);
      expect(find.text('CHỈ BÁO'), findsOneWidget);

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa có ngưỡng'), findsOneWidget);

      expect(find.text('Lưu thay đổi (0)'), findsOneWidget);
      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu thay đổi (0)'),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('edit_row_marks_dirty_and_recomputes_badge_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Enter threshold 20, target 40 for Oxy
      final oxyThresholdField = find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA');
      final oxyTargetField = find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA');

      await tester.enterText(oxyThresholdField, '20');
      await tester.enterText(oxyTargetField, '40');
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Đã sửa'), findsOneWidget);
      expect(find.text('Lưu thay đổi (1)'), findsOneWidget);
      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu thay đổi (1)'),
      );
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('row_error_disables_save_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      final oxyThresholdField = find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA');
      final oxyTargetField = find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA');

      // target 5 < threshold 10
      await tester.enterText(oxyThresholdField, '10');
      await tester.enterText(oxyTargetField, '5');
      await tester.pumpAndSettle();

      expect(
        find.text('Mục tiêu phải lớn hơn hoặc bằng ngưỡng.'),
        findsOneWidget,
      );
      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu thay đổi (1)'),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('list_ready_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(VTable), findsNothing);
      expect(find.text('Lưu thay đổi (0)'), findsNothing);

      expect(find.text('Chưa có ngưỡng'), findsNWidgets(2));
      expect(find.text('Ngưỡng 30 · Mục tiêu 80 hộp'), findsOneWidget);
    });

    testWidgets('staff_read_only_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot(isOwner: false));

      await tester.pumpWidget(buildScreen(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(
        find.text('Chỉ chủ cửa hàng thay đổi được chính sách.'),
        findsOneWidget,
      );

      final row = tester.widget<VListRow>(
        find.widgetWithText(VListRow, 'Nobivac DHPPi'),
      );
      expect(row.type, VListRowType.plain);
      expect(row.onTap, isNull);
    });

    testWidgets('conflict_shows_reload_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenThrow(
        const AppException(
          InventoryErrorCode.versionConflict,
          serverMessage: 'Stale revision',
        ),
      );

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Make dirty
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '40',
      );
      await tester.pumpAndSettle();

      // Open impact sheet and save
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu chính sách'));
      await tester.pumpAndSettle();

      expect(find.text('Chính sách vừa được cập nhật'), findsOneWidget);
      expect(find.text('Tải lại'), findsOneWidget);
    });

    testWidgets('save_error_shows_retry_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenThrow(
        const AppException(AppErrorCode.network, serverMessage: 'Network fail'),
      );

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '40',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu chính sách'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa lưu được chính sách'), findsOneWidget);
      expect(find.widgetWithText(VButton, 'Thử lại'), findsOneWidget);
    });

    testWidgets('expiry_tab_ready_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(
        buildScreen(size: const Size(1280, 800), initialTab: 'expiry'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hành động'), findsNothing);
      expect(find.text('Chặn bán'), findsNothing);
      expect(find.text('Chưa đặt: không đánh dấu lô cận hạn.'), findsOneWidget);
      expect(
        find.text('Chưa có sản phẩm nào có chính sách riêng.'),
        findsOneWidget,
      );
    });

    testWidgets('expiry_zero_days_error_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(
        buildScreen(size: const Size(390, 844), initialTab: 'expiry'),
      );
      await tester.pumpAndSettle();

      final daysField = find.bySemanticsLabel('Số ngày cận hạn');
      await tester.enterText(daysField, '0');
      await tester.pumpAndSettle();

      expect(find.text('Số ngày cận hạn phải lớn hơn 0.'), findsOneWidget);

      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu thay đổi'),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('switch_tab_keeps_draft', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Edit Oxy in threshold tab
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '27',
      );
      await tester.pumpAndSettle();

      // Switch to Expiry tab
      await tester.ensureVisible(find.text('Cận hạn'));
      await tester.tap(find.text('Cận hạn'));
      await tester.pumpAndSettle();

      // Switch back to Ngưỡng tồn
      await tester.ensureVisible(find.text('Ngưỡng tồn'));
      await tester.tap(find.text('Ngưỡng tồn'));
      await tester.pumpAndSettle();

      expect(find.text('27'), findsOneWidget);
    });

    testWidgets('leave_with_draft_asks_confirm', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      // In Expiry tab: edit default days
      await tester.tap(find.text('Cận hạn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.bySemanticsLabel('Số ngày cận hạn'), '45');
      await tester.pumpAndSettle();

      // Press back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      expect(find.text('Ở lại'), findsOneWidget);
      expect(find.text('Bỏ thay đổi'), findsOneWidget);

      // Tap 'Ở lại' keeps screen
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();

      expect(find.text('Chính sách tồn & cận hạn'), findsOneWidget);
    });

    testWidgets('discard_pops_once', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const StockPolicyPage(),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);

      await tester.tap(find.text('Cận hạn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.bySemanticsLabel('Số ngày cận hạn'), '45');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();

      expect(find.text('Go'), findsOneWidget);
      expect(find.byType(StockPolicyPage), findsNothing);
    });

    testWidgets('impact_sheet_lists_changes_and_low_delta_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Edit Oxy to 20/40
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '40',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Lưu 1 thay đổi?'), findsOneWidget);
      expect(
        find.textContaining('Oxytetracycline LA: chưa có → 20 / 40 chai'),
        findsOneWidget,
      );
      expect(find.text('Tồn thấp: 1 → 1 sản phẩm'), findsOneWidget);
    });

    testWidgets('edit_sheet_saves_directly_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      await tester.pumpWidget(buildScreen(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      final nobiRow = find.widgetWithText(VListRow, 'Nobivac DHPPi');
      await tester.tap(nobiRow);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Nobivac DHPPi'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Nobivac DHPPi'),
        '40',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(1);
    });

    testWidgets('retry_after_sheet_error_resends_single', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());
      final capturedKeys = <String>[];
      var callCount = 0;
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((inv) async {
        capturedKeys.add(inv.namedArguments[#idempotencyKey] as String);
        callCount++;
        if (callCount == 1) {
          throw const AppException(
            AppErrorCode.network,
            serverMessage: 'Network fail',
          );
        }
        return 6;
      });

      await tester.pumpWidget(buildScreen(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      final nobiRow = find.widgetWithText(VListRow, 'Nobivac DHPPi');
      await tester.tap(nobiRow);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Nobivac DHPPi'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Nobivac DHPPi'),
        '40',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa lưu được chính sách'), findsOneWidget);
      expect(find.widgetWithText(VButton, 'Thử lại'), findsOneWidget);

      await tester.tap(find.widgetWithText(VButton, 'Thử lại'));
      await tester.pumpAndSettle();

      expect(capturedKeys.length, 2);
      expect(capturedKeys[0], equals(capturedKeys[1]));
      expect(find.text('Chưa lưu được chính sách'), findsNothing);
    });

    testWidgets('add_sheet_lists_only_lot_products', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(
        buildScreen(size: const Size(1280, 800), initialTab: 'expiry'),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(VButton, 'Thêm sản phẩm'));
      await tester.tap(find.widgetWithText(VButton, 'Thêm sản phẩm'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm sản phẩm'), findsNWidgets(2));
      // Nobivac, Enro, Tylo, Oxy are lot-tracked -> visible
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.text('Tylosin 200'), findsOneWidget);
      // Amox is not lot-tracked -> not in sheet
      expect(find.text('Amoxicillin 500'), findsNothing);
    });
  });
}
