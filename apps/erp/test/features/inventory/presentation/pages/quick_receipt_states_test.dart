import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/models/receipt_actor.dart';
import 'package:erp/features/inventory/data/models/receipt_document_model.dart';
import 'package:erp/features/inventory/data/models/receipt_header_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_item_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_lot_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_scenario.dart';
import 'package:erp/features/inventory/data/valuation_repository.dart';
import 'package:erp/features/inventory/logic/quick_receipt_session_cubit.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_approval_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_item_detail_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_items_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_reconciliation_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_review_page.dart';
import 'package:erp/features/inventory/presentation/pages/quick_receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/pages/receipt_entry_choice_page.dart';
import 'package:erp/features/inventory/presentation/pages/receipt_item_detail_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

const _maker = ReceiptActor(id: 'user_a', name: 'Nguyễn Văn An');
const _approver = ReceiptActor(id: 'other_user', name: 'Trần Văn Bình');

ReceiptHeaderDraft _header() => ReceiptHeaderDraft(
  supplierId: 'sup_01',
  supplierName: 'Minh Dũng',
  receiptDate: DateTime(2026, 10, 14),
  documentFileNames: const ['phieu_giao.pdf'],
);

ReceiptItemDraft _amox({
  List<ReceiptLotDraft> lots = const [
    ReceiptLotDraft(
      lotCode: 'L2407-A',
      accepted: 10,
      expiryDate: LotDate(year: 2028, month: 7),
    ),
  ],
}) => ReceiptItemDraft(
  productId: 'prod_01',
  productName: 'Amox 500',
  productCode: 'AMX-500',
  unitId: 'u_hop',
  unitName: 'Hộp',
  isLotTracked: true,
  requiresExpiry: true,
  lots: lots,
);

QuickReceiptSessionCubit _cubit(GoodsReceiptRepository repo) {
  final cubit = QuickReceiptSessionCubit(
    repository: repo,
    actorLoader: () async => _maker,
  );
  cubit.updateHeader(_header());
  return cubit;
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  QuickReceiptSessionCubit? cubit,
}) async {
  _bigScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      home: cubit == null ? page : BlocProvider.value(value: cubit, child: page),
    ),
  );
  await tester.pumpAndSettle();
}

/// Router giống ShellRoute nhập nhanh, dùng chung một Cubit.
Future<GoRouter> _pumpFlow(
  WidgetTester tester,
  QuickReceiptSessionCubit cubit, {
  String initial = '/warehouse/receipts/quick/items',
}) async {
  _bigScreen(tester);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/inventory', builder: (_, _) => const Scaffold()),
      ShellRoute(
        builder: (context, state, child) => BlocProvider.value(value: cubit, child: child),
        routes: [
          GoRoute(
            path: '/warehouse/receipts/quick/header',
            builder: (_, _) => const QuickReceiptHeaderPage(),
          ),
          GoRoute(
            path: '/warehouse/receipts/quick/items',
            builder: (_, _) => const GoodsReceiptItemsPage(),
          ),
          GoRoute(
            path: '/warehouse/receipts/quick/item-detail',
            builder: (_, state) {
              final args = state.extra as ReceiptItemDetailArgs;
              return GoodsReceiptItemDetailPage(
                item: args.item,
                readOnly: args.readOnly,
              );
            },
          ),
          GoRoute(
            path: '/warehouse/receipts/quick/review',
            builder: (_, _) => const GoodsReceiptReviewPage(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

VButton _button(WidgetTester tester, String label) => tester.widget<VButton>(
  find.byWidgetPredicate((w) => w is VButton && w.label == label),
);

/// Gửi + duyệt một phiếu nhập nhanh trên [repo]; trả về id.
Future<String> _submitAndApprove(GoodsReceiptRepository repo) async {
  final scenario = repo.scenario;
  repo.scenario = ReceiptScenario.normal;
  final doc = await repo.submitQuickReceipt(
    _header(),
    [_amox()],
    maker: _maker,
  );
  repo.scenario = scenario;
  await repo.approveReceipt(doc.id, approver: _approver);
  return doc.id;
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerLazySingleton<GoodsReceiptRepository>(
      () => GoodsReceiptRepository(),
    );
  });
  tearDown(getIt.reset);

  group('PR 1: sửa còn lại của T7-0b', () {
    testWidgets('C1: xoá lô A thì thẻ còn lại giữ HSD của lô B', (tester) async {
      final cubit = _cubit(GoodsReceiptRepository());
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(
        _amox(
          lots: const [
            ReceiptLotDraft(
              lotCode: 'A',
              accepted: 1,
              expiryDate: LotDate(year: 2028, month: 7),
            ),
            ReceiptLotDraft(
              lotCode: 'B',
              accepted: 1,
              expiryDate: LotDate(year: 2029, month: 9),
            ),
          ],
        ),
      );
      await _pumpFlow(tester, cubit);
      await tester.tap(find.text('Amox 500').first);
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is VButton && w.semanticLabel == 'Xoá lô',
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('09/2029'), findsOneWidget);
      expect(find.text('07/2028'), findsNothing);
    });

    testWidgets('C2: Sửa ở SCR-010 pop về 009, Back thêm một lần về 008', (tester) async {
      final cubit = _cubit(GoodsReceiptRepository());
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      final router = await _pumpFlow(
        tester,
        cubit,
        initial: '/warehouse/receipts/quick/header',
      );
      router.push('/warehouse/receipts/quick/items');
      await tester.pumpAndSettle();
      router.push('/warehouse/receipts/quick/review');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sửa').last);
      await tester.pumpAndSettle();
      expect(find.text('Hàng thực nhận'), findsWidgets);
      expect(find.text('Rà soát nhận hàng'), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận & tiếp tục'), findsOneWidget);
    });
  });

  group('PR 1: kịch bản của repository', () {
    test('C3: permissionDenied → getCapability ném noPermission', () async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.permissionDenied;
      await expectLater(
        repo.getCapability(),
        throwsA(
          isA<AppException>().having((e) => e.isNoPermission, 'isNoPermission', true),
        ),
      );
    });

    test('C4: catalogChanged → lần 1 stateChanged, lần 2 trả danh mục', () async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.catalogChanged;
      await expectLater(
        repo.getProducts(),
        throwsA(
          isA<AppException>().having((e) => e.isStateChanged, 'isStateChanged', true),
        ),
      );
      expect(await repo.getProducts(), isNotEmpty);
    });

    test('C5: approverMissing → không tạo phiếu', () async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.approverMissing;
      await expectLater(
        repo.submitQuickReceipt(_header(), [_amox()], maker: _maker),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'APPROVER_CONFIGURATION_MISSING'),
        ),
      );
      // Id kế tiếp vẫn là số 01: lần gửi lỗi không cấp receiptId.
      repo.scenario = ReceiptScenario.normal;
      final doc = await repo.submitQuickReceipt(
        _header(),
        [_amox()],
        maker: _maker,
      );
      expect(doc.id, endsWith('-01'));
    });

    test('C6: executionUnknown → kiểm tra lần 2 mới completed và có mục chờ', () async {
      final valuation = ValuationRepository();
      final repo = GoodsReceiptRepository(valuation: valuation)
        ..scenario = ReceiptScenario.executionUnknown;
      final id = await _submitAndApprove(repo);
      expect(
        (await repo.getReceiptById(id))!.status,
        ReceiptStatus.executionUnknown,
      );
      expect(
        (await valuation.getQueue()).where((w) => w.id == id),
        isEmpty,
      );

      expect(
        (await repo.checkReceiptResult(id))!.status,
        ReceiptStatus.executionUnknown,
      );
      expect(
        (await repo.checkReceiptResult(id))!.status,
        ReceiptStatus.completed,
      );
      expect((await valuation.getQueue()).where((w) => w.id == id), hasLength(1));
    });

    test('C7: executionUnknownStuck → luôn unknown, không có mục chờ', () async {
      final valuation = ValuationRepository();
      final repo = GoodsReceiptRepository(valuation: valuation)
        ..scenario = ReceiptScenario.executionUnknownStuck;
      final id = await _submitAndApprove(repo);
      for (var i = 0; i < 5; i++) {
        expect(
          (await repo.checkReceiptResult(id))!.status,
          ReceiptStatus.executionUnknown,
        );
      }
      expect((await valuation.getQueue()).where((w) => w.id == id), isEmpty);
    });

    test('C8: executionRejected → không có mục chờ định giá', () async {
      final valuation = ValuationRepository();
      final repo = GoodsReceiptRepository(valuation: valuation)
        ..scenario = ReceiptScenario.executionRejected;
      final id = await _submitAndApprove(repo);
      expect(
        (await repo.getReceiptById(id))!.status,
        ReceiptStatus.executionRejected,
      );
      expect((await valuation.getQueue()).where((w) => w.id == id), isEmpty);
    });
  });

  group('PR 2: SCR-006 / 008 / 009', () {
    testWidgets('C9: SCR-006 không quyền', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.permissionDenied;
      await _pumpPage(tester, ReceiptEntryChoicePage(repository: repo));

      expect(find.text('Không có quyền truy cập'), findsOneWidget);
      expect(find.text('Nhập hàng nhanh'), findsNothing);
    });

    testWidgets('C10: SCR-006 kho khoá → thẻ nhập nhanh không chạm được', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.warehouseLocked;
      await _pumpPage(tester, ReceiptEntryChoicePage(repository: repo));

      expect(find.text('Kho đang được khóa'), findsOneWidget);
      final ignore = find.ancestor(
        of: find.text('Nhập hàng nhanh'),
        matching: find.byType(IgnorePointer),
      );
      expect(
        tester.widgetList<IgnorePointer>(ignore).any((w) => w.ignoring),
        isTrue,
      );
    });

    testWidgets('C11: SCR-009 danh mục vừa đổi → Tải lại', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.catalogChanged;
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      await _pumpFlow(tester, cubit);

      expect(find.text('Dữ liệu vừa thay đổi'), findsOneWidget);
      await tester.tap(find.text('Tải lại'));
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu vừa thay đổi'), findsNothing);
      expect(find.text('Amox 500'), findsOneWidget);
    });

    testWidgets('C12: SCR-009 kho khoá → không ô tìm kiếm, Rà soát tắt', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.warehouseLocked;
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      await _pumpFlow(tester, cubit);

      expect(find.text('Kho đang được khóa'), findsOneWidget);
      expect(find.byType(VSearchBar), findsNothing);
      expect(_button(tester, 'Rà soát').enabled, isFalse);
    });

    testWidgets('C13: SCR-008 bấm tiếp tục khi chưa đủ', (tester) async {
      final cubit = QuickReceiptSessionCubit(
        repository: GoodsReceiptRepository(),
        actorLoader: () async => _maker,
      );
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      await _pumpPage(tester, const QuickReceiptHeaderPage(), cubit: cubit);

      await tester.tap(find.text('Xác nhận & tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Cần kiểm tra dữ liệu'), findsOneWidget);
      expect(find.text('Chọn nhà cung cấp trong danh sách.'), findsOneWidget);
    });

    testWidgets('C14: SCR-009 dòng chưa xong, Rà soát → ở lại 009', (tester) async {
      final cubit = _cubit(GoodsReceiptRepository());
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox(lots: const [ReceiptLotDraft(lotCode: 'X')]));
      await _pumpFlow(tester, cubit);

      await tester.tap(find.text('Rà soát'));
      await tester.pumpAndSettle();

      expect(find.text('Cần kiểm tra dữ liệu'), findsOneWidget);
      expect(find.text('Chưa hoàn tất — mở để sửa'), findsOneWidget);
      expect(find.text('Hàng thực nhận'), findsWidgets);
      expect(find.text('Rà soát nhận hàng'), findsNothing);
    });
  });

  group('PR 2: SCR-010 / 011 / 012', () {
    testWidgets('C15: SCR-010 chưa có người duyệt', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.approverMissing;
      final cubit = _cubit(repo);
      addTearDown(cubit.close);
      cubit.saveItem(_amox());
      await _pumpPage(tester, const GoodsReceiptReviewPage(), cubit: cubit);

      await tester.tap(find.text('Gửi phê duyệt'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có người duyệt phù hợp'), findsOneWidget);
      expect(find.text('Chưa gửi được'), findsNothing); // không toast
      expect(find.text('Cần phê duyệt trước khi ghi nhận'), findsNothing);
      expect(_button(tester, 'Gửi phê duyệt').enabled, isTrue);
    });

    testWidgets('C16: SCR-011 id không tồn tại', (tester) async {
      await _pumpPage(
        tester,
        GoodsReceiptApprovalPage(
          receiptId: 'REC-KHONG-CO',
          repository: GoodsReceiptRepository(),
          actorLoader: () async => _approver,
        ),
      );
      expect(find.text('Không có yêu cầu để duyệt'), findsOneWidget);
    });

    testWidgets('C17: SCR-012 đang ghi nhận → tự cập nhật thành đã ghi nhận', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.executionProcessing;
      final id = await _submitAndApprove(repo);
      _bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptResultPage(
            receiptId: id,
            repository: repo,
            pollInterval: const Duration(milliseconds: 10),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Đang ghi nhận hàng'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
      expect(find.text('Đã ghi nhận hàng'), findsOneWidget);
    });

    testWidgets('C18: SCR-012 chưa rõ kết quả', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.executionUnknown;
      final id = await _submitAndApprove(repo);
      await _pumpPage(
        tester,
        GoodsReceiptResultPage(receiptId: id, repository: repo),
      );

      expect(find.text('Đang xác minh kết quả'), findsOneWidget);
      expect(find.text('Giữ nguyên lần nhận hiện tại'), findsOneWidget);
      expect(find.text('Xác minh kết quả'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is VButton && w.semanticLabel == 'Quay lại',
        ),
        findsNothing,
      );
    });

    testWidgets('C21: SCR-012 bị chặn khi ghi nhận', (tester) async {
      final valuation = ValuationRepository();
      final repo = GoodsReceiptRepository(valuation: valuation)
        ..scenario = ReceiptScenario.executionRejected;
      final id = await _submitAndApprove(repo);
      await _pumpPage(
        tester,
        GoodsReceiptResultPage(receiptId: id, repository: repo),
      );

      expect(find.text('Chưa ghi nhận hàng'), findsOneWidget);
      expect((await valuation.getQueue()).where((w) => w.id == id), isEmpty);
    });
  });

  group('PR 2: SCR-013', () {
    testWidgets('C19: mở rồi Làm mới → Đã xác lập kết quả', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.executionUnknown;
      final id = await _submitAndApprove(repo);
      await _pumpPage(
        tester,
        GoodsReceiptReconciliationPage(
          receiptId: id,
          repository: repo,
          autoReturnDelay: const Duration(hours: 1),
        ),
      );

      expect(find.text('Đang kiểm tra biến động tồn kho'), findsOneWidget);
      expect(find.text('Biến động tồn kho đã được ghi'), findsNothing);

      await tester.tap(find.text('Làm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Đã xác lập kết quả'), findsOneWidget);
      expect(find.text('Biến động tồn kho đã được ghi'), findsOneWidget);
      expect(find.text('Xem kết quả'), findsOneWidget);
      // Dọn Timer tự chuyển màn.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('C20: chưa có kết quả quá 1 phút → dữ liệu có thể đã cũ', (tester) async {
      final repo = GoodsReceiptRepository()..scenario = ReceiptScenario.executionUnknownStuck;
      final id = await _submitAndApprove(repo);
      var now = DateTime(2026, 10, 14, 9);
      await _pumpPage(
        tester,
        GoodsReceiptReconciliationPage(
          receiptId: id,
          repository: repo,
          clock: () => now,
        ),
      );
      expect(find.text('Dữ liệu có thể đã cũ'), findsNothing);

      // Đồng hồ chạy thêm 2 phút, cubit vẫn giữ lần kiểm tra cũ.
      now = now.add(const Duration(minutes: 2));
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptReconciliationPage(
            receiptId: id,
            repository: repo,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu có thể đã cũ'), findsOneWidget);
      expect(find.text('Xem hỗ trợ xử lý'), findsNothing);
    });
  });
}
