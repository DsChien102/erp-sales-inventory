import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/models/receipt_actor.dart';
import 'package:erp/features/inventory/data/models/receipt_header_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_item_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_lot_draft.dart';
import 'package:erp/features/inventory/logic/quick_receipt_session_cubit.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_approval_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_item_detail_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_items_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_review_page.dart';
import 'package:erp/features/inventory/presentation/pages/receipt_entry_choice_page.dart';
import 'package:erp/features/inventory/presentation/pages/receipt_item_detail_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

const _maker = ReceiptActor(id: 'user_a', name: 'Nguyễn Văn An');

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
}) =>
    ReceiptItemDraft(
      productId: 'prod_01',
      productName: 'Amox 500',
      productCode: 'AMX-500',
      unitId: 'u_hop',
      unitName: 'Hộp',
      isLotTracked: true,
      requiresExpiry: true,
      lots: lots,
      knownLotExpiry: const {'L2407-A': LotDate(year: 2028, month: 7)},
    );

QuickReceiptSessionCubit _newCubit({bool withHeader = true}) {
  final cubit = QuickReceiptSessionCubit(
    repository: GoodsReceiptRepository(),
    actorLoader: () async => _maker,
  );
  if (withHeader) cubit.updateHeader(_header());
  return cubit;
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Dựng router giống ShellRoute nhập nhanh: mọi trang dùng chung một Cubit.
Future<void> _pumpFlow(
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
        builder: (context, state, child) =>
            BlocProvider.value(value: cubit, child: child),
        routes: [
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
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
  );
  await tester.pumpAndSettle();
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
      home: cubit == null
          ? page
          : BlocProvider.value(value: cubit, child: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    getIt.reset();
    getIt.registerLazySingleton<GoodsReceiptRepository>(
      () => GoodsReceiptRepository(),
    );
  });
  tearDown(getIt.reset);

  group('SCR-006', () {
    testWidgets('B9: thứ tự thẻ, thẻ chứng từ không chạm được, không badge',
        (tester) async {
      await _pumpPage(tester, const ReceiptEntryChoicePage());

      expect(find.text('Nhận hàng'), findsOneWidget);
      expect(find.text('Chưa có chứng từ mua chờ nhận.'), findsOneWidget);
      expect(find.byType(VChip), findsNothing);

      final doc = tester.getTopLeft(find.text('Nhận theo chứng từ')).dy;
      final quick = tester.getTopLeft(find.text('Nhập hàng nhanh')).dy;
      expect(doc, lessThan(quick));

      final ignore = find.ancestor(
        of: find.text('Nhận theo chứng từ'),
        matching: find.byType(IgnorePointer),
      );
      expect(
        tester.widgetList<IgnorePointer>(ignore).any((w) => w.ignoring),
        isTrue,
      );
    });
  });

  group('SCR-009', () {
    testWidgets('B10: gõ glove còn một kết quả, chạm mở editor', (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      await _pumpFlow(tester, cubit);

      await tester.enterText(find.byType(TextField), 'glove');
      await tester.pumpAndSettle();
      expect(find.text('Găng tay khám Nitrile'), findsOneWidget);
      expect(find.text('Amox 500'), findsNothing);

      await tester.tap(find.text('Găng tay khám Nitrile'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết hàng thực nhận'), findsOneWidget);
    });

    testWidgets('B11: nhiều đơn vị chọn trực tiếp, đơn vị đã có được đánh dấu',
        (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      await _pumpFlow(tester, cubit);

      await tester.enterText(find.byType(TextField), 'amox');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amox 500').first);
      await tester.pumpAndSettle();

      expect(find.text('Hộp'), findsOneWidget);
      expect(find.text('Vỉ'), findsOneWidget);
      expect(find.text('Viên'), findsOneWidget);
      expect(find.text('Đã có trong lần nhận'), findsOneWidget);
    });

    testWidgets('B12: không có kết quả → câu hướng dẫn', (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      await _pumpFlow(tester, cubit);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sản phẩm chưa có trong danh mục'),
        findsOneWidget,
      );
    });
  });

  group('SCR-084', () {
    Future<void> openDetail(
      WidgetTester tester,
      QuickReceiptSessionCubit cubit,
    ) async {
      await _pumpFlow(tester, cubit);
      await tester.tap(find.text('Amox 500').first);
      await tester.pumpAndSettle();
    }

    testWidgets('B13: Từ chối = 5 hiện "Không vào tồn"', (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      await openDetail(tester, cubit);

      expect(find.text('Không vào tồn'), findsNothing);
      final rejected = find.descendant(
        of: find.byType(VNumberField).at(3),
        matching: find.byType(TextField),
      );
      await tester.enterText(rejected, '5');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Không vào tồn'), findsOneWidget);
    });

    testWidgets('B14: HSD 13/2026 theo Tháng/năm báo sai định dạng',
        (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      await openDetail(tester, cubit);

      await tester.tap(find.text('Tháng/năm'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '13/2026');
      await tester.pumpAndSettle();
      expect(find.text('Hạn dùng không đúng định dạng'), findsOneWidget);
    });

    testWidgets('B15: dòng đã có → Xóa khỏi lần nhận → Xóa', (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      await cubit.loadCatalog();
      cubit.saveItem(_amox());
      await openDetail(tester, cubit);

      await tester.tap(find.text('Xóa khỏi lần nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Xóa khỏi lần nhận?'), findsOneWidget);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      expect(cubit.state.items, isEmpty);
    });
  });

  group('SCR-010', () {
    testWidgets('B16: chỉ có Từ chối → banner cảnh báo, nút tắt',
        (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      cubit.saveItem(_amox(lots: const [
        ReceiptLotDraft(
          lotCode: 'L2407-A',
          rejected: 4,
          expiryDate: LotDate(year: 2028, month: 7),
        ),
      ]));
      await _pumpPage(tester, const GoodsReceiptReviewPage(), cubit: cubit);

      expect(find.text('Chưa có hàng vào tồn'), findsOneWidget);
      final button = tester.widget<VButton>(
        find.byWidgetPredicate((w) => w is VButton && w.label == 'Gửi phê duyệt'),
      );
      expect(button.enabled, isFalse);
    });

    testWidgets('B17: dòng LOT hiện mã lô và HSD', (tester) async {
      final cubit = _newCubit();
      addTearDown(cubit.close);
      cubit.saveItem(_amox());
      await _pumpPage(tester, const GoodsReceiptReviewPage(), cubit: cubit);

      expect(find.text('Cần phê duyệt trước khi ghi nhận'), findsOneWidget);
      expect(find.text('Lô L2407-A'), findsOneWidget);
      expect(find.text('HSD 07/2028'), findsOneWidget);
      expect(find.text('Ghi chú'), findsNothing);
    });
  });

  group('SCR-011 / SCR-012', () {
    const approver = ReceiptActor(id: 'other_user', name: 'Trần Văn Bình');

    testWidgets('B18: tiêu đề, banner lý do, nút Duyệt', (tester) async {
      await _pumpPage(
        tester,
        GoodsReceiptApprovalPage(
          receiptId: 'REC-240715-01',
          repository: GoodsReceiptRepository(),
          actorLoader: () async => approver,
        ),
      );

      expect(find.text('Phê duyệt yêu cầu nhận hàng'), findsOneWidget);
      expect(find.textContaining('Nguyễn Văn An gửi'), findsOneWidget);
      expect(find.text('Lý do cần duyệt'), findsOneWidget);
      expect(find.text('Duyệt'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
      expect(find.text('Lô L2407-A'), findsOneWidget);
      expect(find.text('HSD 07/2028'), findsOneWidget);
    });

    testWidgets('B19: kết quả sau khi duyệt', (tester) async {
      final repo = GoodsReceiptRepository();
      await repo.approveReceipt('REC-240715-01', approver: approver);
      await _pumpPage(
        tester,
        GoodsReceiptResultPage(receiptId: 'REC-240715-01', repository: repo),
      );

      expect(find.text('Đã ghi nhận hàng'), findsOneWidget);
      expect(find.text('Kết quả theo dòng hàng'), findsOneWidget);
      expect(find.text('Đang chờ xác nhận giá'), findsOneWidget);
      expect(find.text('Xác lập giá trị'), findsOneWidget);
    });
  });
}
