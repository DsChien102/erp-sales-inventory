import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/models/receipt_actor.dart';
import 'package:erp/features/inventory/data/models/receipt_document_model.dart';
import 'package:erp/features/inventory/data/models/receipt_header_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_item_draft.dart';
import 'package:erp/features/inventory/data/models/receipt_lot_draft.dart';
import 'package:erp/features/inventory/logic/quick_receipt_session_cubit.dart';
import 'package:erp/features/inventory/logic/receipt_approval_cubit.dart';
import 'package:erp/features/inventory/logic/receipt_approval_state.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_approval_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/pages/goods_receipt_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  setUp(() {
    getIt.reset();
    getIt.registerLazySingleton<GoodsReceiptRepository>(
      () => GoodsReceiptRepository(),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  group('BJ-02: Quick Receipt Flow Tests', () {
    test(
        'QuickReceiptSessionCubit handles full drafting and submission correctly',
        () async {
      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async =>
            const ReceiptActor(id: 'user_a', name: 'Nguyễn Văn An'),
      );

      expect(cubit.state.header.isValid, isFalse);
      expect(cubit.state.canReview, isFalse);

      // 1. Update header
      cubit.updateHeader(
        cubit.state.header.copyWith(
          supplierId: 'sup_01',
          supplierName: 'Minh Dũng',
          warehouseId: 'wh_01',
          warehouseName: 'Kho trung tâm',
          documentFileNames: const ['bien_ban.pdf'],
        ),
      );
      expect(cubit.state.header.isValid, isTrue);
      expect(cubit.state.canReview, isFalse);

      // 2. Add an item with lots and 4-tier quantities
      final item = ReceiptItemDraft(
        productId: 'prod_01',
        productName: 'Amox 500',
        productCode: 'AMX-500',
        unitId: 'u_hop',
        unitName: 'Hộp',
        isLotTracked: true,
        lots: [
          ReceiptLotDraft(
            lotCode: 'LOT-01',
            accepted: 80.0,
            quarantine: 2.0,
            damaged: 1.0,
            rejected: 0.0,
          ),
        ],
      );

      // Business Rule: Total = Accepted + Quarantine + Damaged + Rejected
      expect(item.totalReceived, equals(83.0));
      // Physical stock excludes rejected
      expect(item.totalPhysicalStock, equals(83.0));

      cubit.saveItem(item);
      expect(cubit.state.items.length, equals(1));
      expect(cubit.state.canReview, isTrue);

      // 3. Submit for approval
      final doc = await cubit.submitForApproval();
      expect(doc, isNotNull);
      expect(doc!.status, equals(ReceiptStatus.pendingApproval));
      expect(doc.header.supplierName, equals('Minh Dũng'));
      expect(doc.items.first.productName, equals('Amox 500'));
    });

    test('ReceiptApprovalCubit approves and rejects receipts correctly',
        () async {
      final repo = GoodsReceiptRepository();
      const maker = ReceiptActor(id: 'user_maker', name: 'Người Lập');
      const approver = ReceiptActor(id: 'user_approver', name: 'Trưởng Kho');

      final header = ReceiptHeaderDraft(
        supplierId: 'sup_01',
        supplierName: 'Minh Dũng',
        warehouseId: 'wh_01',
        receiptDate: DateTime.now(),
        documentFileNames: const ['doc.pdf'],
      );

      final doc = await repo.submitQuickReceipt(
        header,
        const [],
        maker: maker,
      );

      final cubit = ReceiptApprovalCubit(
        repository: repo,
        actorLoader: () async => approver,
      );

      await cubit.load(doc.id);
      expect(cubit.state, isA<ReceiptApprovalLoaded>());

      // Approve
      await cubit.approve();
      expect(cubit.state, isA<ReceiptApprovalSuccess>());
      final approvedDoc = (cubit.state as ReceiptApprovalSuccess).document;
      expect(approvedDoc.status, equals(ReceiptStatus.completed));
      expect(approvedDoc.decidedByName, equals('Trưởng Kho'));

      // Create another doc for reject
      final doc2 = await repo.submitQuickReceipt(
        header,
        const [],
        maker: maker,
      );

      final cubit2 = ReceiptApprovalCubit(
        repository: repo,
        actorLoader: () async => approver,
      );
      await cubit2.load(doc2.id);
      await cubit2.reject(reason: 'Bao bì bị rách');
      expect(cubit2.state, isA<ReceiptApprovalSuccess>());
      final rejectedDoc = (cubit2.state as ReceiptApprovalSuccess).document;
      expect(rejectedDoc.status, equals(ReceiptStatus.rejected));
      expect(rejectedDoc.rejectReason, equals('Bao bì bị rách'));
    });

    testWidgets(
        'T17: GoodsReceiptApprovalPage blocks self approval when actor is maker',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = GoodsReceiptRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptApprovalPage(
            receiptId: 'REC-240715-01',
            repository: repo,
            actorLoader: () async => const ReceiptActor(
              id: 'fixture-maker',
              name: 'Nguyễn Văn An',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bạn không thể tự duyệt'), findsOneWidget);
      expect(find.text('Duyệt'), findsNothing);
    });

    testWidgets(
        'GoodsReceiptApprovalPage allows other actor to approve',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = GoodsReceiptRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptApprovalPage(
            receiptId: 'REC-240715-01',
            repository: repo,
            actorLoader: () async => const ReceiptActor(
              id: 'other_user',
              name: 'Trần Văn Bình',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Từ chối'), findsOneWidget);
      expect(find.text('Duyệt'), findsOneWidget);
    });

    testWidgets('T16: GoodsReceiptReviewPage renders pending state after submission',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = GoodsReceiptRepository();
      final cubit = QuickReceiptSessionCubit(
        repository: repo,
        actorLoader: () async => const ReceiptActor(
          id: 'user_a',
          name: 'Nguyễn Văn An',
        ),
      );

      cubit.updateHeader(
        ReceiptHeaderDraft(
          supplierId: 'sup_01',
          supplierName: 'Minh Dũng',
          warehouseId: 'wh_01',
          receiptDate: DateTime.now(),
          documentFileNames: const ['doc.pdf'],
        ),
      );
      cubit.saveItem(
        const ReceiptItemDraft(
          productId: 'prod_01',
          productName: 'Amox 500',
          productCode: 'AMX-500',
          unitId: 'u_hop',
          unitName: 'Hộp',
          lots: [ReceiptLotDraft(accepted: 10)],
        ),
      );

      await cubit.submitForApproval();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider.value(
            value: cubit,
            child: const GoodsReceiptReviewPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã gửi phê duyệt'), findsOneWidget);
      expect(find.text('Về Kho'), findsWidgets);
      expect(find.text('Gửi phê duyệt'), findsNothing);
    });

    testWidgets('GoodsReceiptResultPage renders correctly for existing receipt',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = GoodsReceiptRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptResultPage(
            receiptId: 'REC-240715-01',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả nhận hàng'), findsOneWidget);
      expect(find.text('Yêu cầu đang chờ phê duyệt'), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
      expect(find.text('Mã phiếu'), findsNothing);
    });

    testWidgets('GoodsReceiptResultPage renders empty state for non-existent receipt',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = GoodsReceiptRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: GoodsReceiptResultPage(
            receiptId: 'REC-KHONG-CO',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy lần nhận hàng'), findsOneWidget);
      expect(find.text('Về Kho'), findsOneWidget);
    });
  });
}
