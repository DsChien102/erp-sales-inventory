import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor_page.dart';

class _FakeReceiptRepository extends Fake implements GoodsReceiptRepository {
  late ReceiptFormOptions options;
  @override
  Future<ReceiptFormOptions> formOptions() async => options;
}

class _FakeProgramRepository extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async => [];
}

void main() {
  late _FakeReceiptRepository receiptRepo;
  late _FakeProgramRepository programRepo;

  const supplierA = ReceiptSupplierOption(id: 's-1', name: 'Công ty Á Châu', code: 'AC', isSystem: false);

  const productLot = ReceiptProductOption(
    id: 'p-lot',
    name: 'Vắc xin Dại',
    code: 'SP-LOT',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: true,
    expiryRequired: true,
    units: [ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true)],
  );

  setUp(() {
    receiptRepo = _FakeReceiptRepository();
    receiptRepo.options = const ReceiptFormOptions(
      warehouseName: 'Kho chính',
      today: '2026-11-10',
      suppliers: [supplierA],
      products: [productLot],
      lots: [
        KnownLot(
          productId: 'p-lot',
          code: 'DH1',
          expiry: LotDate(year: 2026, month: 11, day: 30),
        ),
      ],
    );
    programRepo = _FakeProgramRepository();
  });

  Widget wrap(ReceiptDraftCubit cubit, String lineKey, {VoidCallback? onDone}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: BlocProvider.value(
        value: cubit,
        child: ReceiptLineEditorPage(
          lineKey: lineKey,
          onDone: onDone ?? () {},
        ),
      ),
    );
  }

  group('ReceiptLineEditor', () {
    testWidgets('known_lot_prefills_expiry_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: Duration.zero,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-lot', 'u-1');

      await tester.pumpWidget(wrap(cubit, lineKey));
      await tester.pumpAndSettle();

      // Gõ mã lô "dh1"
      final lotCodeField = find.byType(VTextField).first;
      await tester.enterText(lotCodeField, 'dh1');
      await tester.pumpAndSettle();

      // Hạn dùng được tự điền "30/11/2026"
      expect(find.text('30/11/2026'), findsOneWidget);
    });

    testWidgets('tier_field_only_for_tier_program_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: Duration.zero,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-lot', 'u-1');

      await tester.pumpWidget(wrap(cubit, lineKey));
      await tester.pumpAndSettle();

      // Chưa có gợi ý tierDiscount -> không có ô "% giảm theo bậc"
      expect(find.text('% giảm theo bậc'), findsNothing);

      // Thêm hint tierDiscount
      cubit.updateLine(lineKey, (l) => l.copyWith(
        hint: const ProgramHint(
          programId: 'pr-tier',
          programName: 'Giảm bậc',
          kind: ProgramKind.tierDiscount,
          tier: (minQty: 10, percent: 5.0, discountVnd: 50000),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('% giảm theo bậc'), findsOneWidget);
    });

    testWidgets('free_helper_and_error_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: Duration.zero,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-lot', 'u-1');

      await tester.pumpWidget(wrap(cubit, lineKey));
      await tester.pumpAndSettle();

      // Ô SL tặng có helper
      expect(find.text('Gồm trong số lượng nhận ở trên.'), findsOneWidget);

      // Đặt số lượng nhận là 5, SL tặng là 5 (free >= total) -> hiện lỗi
      cubit.updateLine(lineKey, (l) => l.copyWith(
        lots: [l.lots.first.copyWith(quantity: 5, code: 'DH1', expiryText: '30/11/2026')],
        unitPriceVnd: 100000,
        freeQty: 5,
      ));
      await tester.pumpAndSettle();

      expect(find.text('SL tặng phải nhỏ hơn số lượng nhận'), findsNWidgets(2));
    });

    testWidgets('done_reason_texts_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: Duration.zero,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-lot', 'u-1');

      await tester.pumpWidget(wrap(cubit, lineKey));
      await tester.pumpAndSettle();

      // Khi mới mở: chưa nhập mã lô -> chân hiện "Nhập mã lô"
      expect(find.text('Nhập mã lô'), findsOneWidget);

      await tester.tap(find.text('Nhập mã lô').first);
      await tester.pumpAndSettle();
      // Nhập mã lô -> hiện "Nhập hạn dùng"
      cubit.updateLine(lineKey, (l) => l.copyWith(
        lots: [l.lots.first.copyWith(code: 'L01')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nhập hạn dùng'), findsOneWidget);
    });

    testWidgets('receipt_line_compare_link', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(
        repository: receiptRepo,
        programs: programRepo,
        hintDebounce: Duration.zero,
      );
      await cubit.load();
      cubit.selectSupplier(supplierA);
      final lineKey = cubit.addLine('p-lot', 'u-1');
      cubit.updateLine(
        lineKey,
        (l) => l.copyWith(
          lots: [l.lots.first.copyWith(code: 'DRAFT-LOT')],
          unitPriceVnd: 95000,
        ),
      );

      String? pushedUri;
      final router = GoRouter(
        initialLocation: '/editor',
        routes: [
          GoRoute(
            path: '/editor',
            builder: (_, _) => BlocProvider.value(
              value: cubit,
              child: ReceiptLineEditorPage(
                lineKey: lineKey,
                onDone: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/warehouse/stock/:productId/suppliers',
            builder: (context, state) {
              pushedUri = state.uri.toString();
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại dòng'),
                  ),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('So sánh nhà cung cấp'), findsOneWidget);
      await tester.tap(find.text('So sánh nhà cung cấp'));
      await tester.pumpAndSettle();

      expect(pushedUri, '/warehouse/stock/p-lot/suppliers');
      expect(find.text('Quay lại dòng'), findsOneWidget);

      await tester.tap(find.text('Quay lại dòng'));
      await tester.pumpAndSettle();

      expect(find.text('DRAFT-LOT'), findsOneWidget);
    });
  });
}
