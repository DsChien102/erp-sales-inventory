import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_lines_page.dart';

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

  const product1 = ReceiptProductOption(
    id: 'p-1',
    name: 'Nobivac DHPPi',
    code: 'NOB-1',
    barcode: null,
    baseUom: 'hộp',
    isLotTracked: false,
    expiryRequired: false,
    units: [ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true)],
  );

  setUp(() {
    receiptRepo = _FakeReceiptRepository();
    receiptRepo.options = const ReceiptFormOptions(
      warehouseName: 'Kho chính',
      today: '2026-11-10',
      suppliers: [supplierA],
      products: [product1],
      lots: [],
    );
    programRepo = _FakeProgramRepository();
  });

  Widget wrap(ReceiptDraftCubit cubit, {VoidCallback? onContinue, ValueChanged<String>? onEditLine}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: BlocProvider.value(
        value: cubit,
        child: ReceiptLinesPage(
          onContinue: onContinue ?? () {},
          onEditLine: onEditLine ?? (_) {},
        ),
      ),
    );
  }

  group('ReceiptLinesPage', () {
    testWidgets('lines_reason_footer_390', (tester) async {
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

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Khi 0 dòng
      expect(find.text('Thêm ít nhất một mặt hàng'), findsOneWidget);

      // Thêm 1 dòng nhưng chưa hoàn tất (giá = 0, SL = 0)
      final lineKey = cubit.addLine('p-1', 'u-1');
      await tester.pumpAndSettle();
      expect(find.text('Còn 1 mặt hàng chưa xử lý'), findsOneWidget);

      // Hoàn tất dòng
      cubit.updateLine(lineKey, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 10)],
      ));
      await tester.pumpAndSettle();

      // Nút Tiếp tục được bật, không còn lý do lỗi
      expect(find.text('Còn 1 mặt hàng chưa xử lý'), findsNothing);
      expect(find.text('Thêm ít nhất một mặt hàng'), findsNothing);
    });

    testWidgets('offer_subline_shown_390', (tester) async {
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

      final lineKey = cubit.addLine('p-1', 'u-1');
      cubit.updateLine(lineKey, (l) => l.copyWith(
        unitPriceVnd: 100000,
        tierPercent: 5.0,
        tierEdited: true,
        freeQty: 1,
        freeEdited: true,
        lots: [l.lots.first.copyWith(quantity: 11)],
      ));

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Giảm 5% · tặng 1 hộp'), findsOneWidget);
    });

    testWidgets('web_split_editor_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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
      cubit.addLine('p-1', 'u-1');

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Trên màn hình 1280px web có cả danh sách bên trái và editor bên phải
      expect(find.text('Hàng thực nhận'), findsOneWidget);
      expect(find.text('Chi tiết hàng thực nhận'), findsOneWidget);
    });
  });
}
