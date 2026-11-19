import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_supplier_field.dart';

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
  const supplierWalkIn = ReceiptSupplierOption(id: 's-walkin', name: 'Nhà cung cấp vãng lai', code: null, isSystem: true);

  setUp(() {
    receiptRepo = _FakeReceiptRepository();
    receiptRepo.options = const ReceiptFormOptions(
      warehouseName: 'Kho chính',
      today: '2026-11-10',
      suppliers: [supplierA, supplierWalkIn],
      products: [],
      lots: [],
    );
    programRepo = _FakeProgramRepository();
  });

  Widget wrap(
    ReceiptDraftCubit cubit, {
    VoidCallback? onContinue,
    VoidCallback? onDiscard,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: BlocProvider.value(
        value: cubit,
        child: ReceiptHeaderPage(
          onContinue: onContinue ?? () {},
          onDiscard: onDiscard,
        ),
      ),
    );
  }

  group('ReceiptHeaderPage', () {
    testWidgets('header_requires_supplier_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(repository: receiptRepo, programs: programRepo);
      await cubit.load();

      bool continued = false;
      await tester.pumpWidget(wrap(cubit, onContinue: () => continued = true));
      await tester.pumpAndSettle();

      // Bấm "Tiếp tục" khi chưa chọn NCC
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(continued, isFalse);
      expect(find.text('Chọn nhà cung cấp trong danh sách.'), findsOneWidget);
    });

    testWidgets('walk_in_first_in_sheet_390', (tester) async {
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

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Mở ô chọn NCC
      await tester.tap(find.byType(ReceiptSupplierField));
      await tester.pumpAndSettle();

      // NCC vãng lai phải xuất hiện trong sheet
      expect(find.text('Nhà cung cấp vãng lai'), findsOneWidget);
      expect(find.text('Công ty Á Châu'), findsOneWidget);

      final walkInPos = tester.getTopLeft(find.text('Nhà cung cấp vãng lai'));
      final aPos = tester.getTopLeft(find.text('Công ty Á Châu'));
      expect(walkInPos.dy, lessThan(aPos.dy));
    });

    testWidgets('back_with_data_asks_discard_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = ReceiptDraftCubit(repository: receiptRepo, programs: programRepo);
      await cubit.load();
      cubit.selectSupplier(supplierA);

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Bấm nút Back trên App Bar
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.tap(find.byIcon(Icons.arrow_back));
      }
      await tester.pumpAndSettle();

      expect(find.text('Bỏ phiếu đang lập?'), findsOneWidget);
      expect(find.text('Thông tin và các dòng hàng đã nhập sẽ mất.'), findsOneWidget);
      expect(find.text('Bỏ phiếu'), findsOneWidget);
      expect(find.text('Ở lại'), findsOneWidget);
    });

    testWidgets('back_with_data_confirms_discard_invokes_on_discard', (tester) async {
      final cubit = ReceiptDraftCubit(repository: receiptRepo, programs: programRepo);
      await cubit.load();
      cubit.selectSupplier(supplierA);

      bool discarded = false;
      await tester.pumpWidget(wrap(cubit, onDiscard: () => discarded = true));
      await tester.pumpAndSettle();

      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Bỏ phiếu đang lập?'), findsOneWidget);

      await tester.tap(find.text('Bỏ phiếu'));
      await tester.pumpAndSettle();

      expect(discarded, isTrue);
    });

    testWidgets('back_empty_draft_invokes_on_discard', (tester) async {
      final cubit = ReceiptDraftCubit(repository: receiptRepo, programs: programRepo);
      await cubit.load();

      bool discarded = false;
      await tester.pumpWidget(wrap(cubit, onDiscard: () => discarded = true));
      await tester.pumpAndSettle();

      final backButton = find.byType(BackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(discarded, isTrue);
    });

    testWidgets('doc_no_limited_to_60_characters', (tester) async {
      final cubit = ReceiptDraftCubit(repository: receiptRepo, programs: programRepo);
      await cubit.load();

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      final docNoFinder = find.byKey(const Key('receipt_doc_no'));
      expect(docNoFinder, findsOneWidget);

      final over60Text = 'A' * 65;
      await tester.enterText(docNoFinder, over60Text);
      await tester.pumpAndSettle();

      final textField = tester.widget<VTextField>(docNoFinder);
      expect(textField.controller?.text.length, 60);
      expect(cubit.state.draft.docNo.length, 60);
    });
  });
}
