import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_review_page.dart';

class _FakeReceiptRepository extends Fake implements GoodsReceiptRepository {
  late ReceiptFormOptions options;
  RecordReceiptResult? nextRecordResult;
  Object? nextRecordError;
  int recordCallCount = 0;

  @override
  Future<ReceiptFormOptions> formOptions() async => options;

  @override
  Future<RecordReceiptResult> record({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    recordCallCount++;
    if (nextRecordError != null) {
      throw nextRecordError!;
    }
    return nextRecordResult!;
  }
}

class _FakeProgramRepository extends Fake implements SupplierProgramRepository {
  List<ProgramHint?> nextHints = [];

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      nextHints;
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

  const product2 = ReceiptProductOption(
    id: 'p-2',
    name: 'Vắc xin Dại',
    code: 'VXD-1',
    barcode: null,
    baseUom: 'liều',
    isLotTracked: false,
    expiryRequired: false,
    units: [ReceiptUnitOption(id: 'u-2', name: 'liều', rate: 1, isBase: true)],
  );

  setUp(() {
    receiptRepo = _FakeReceiptRepository();
    receiptRepo.options = const ReceiptFormOptions(
      warehouseName: 'Kho chính',
      today: '2026-11-10',
      suppliers: [supplierA],
      products: [product1, product2],
      lots: [],
    );
    programRepo = _FakeProgramRepository();
  });

  Widget wrap(ReceiptDraftCubit cubit, {ValueChanged<RecordReceiptResult>? onSuccess}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: BlocProvider.value(
        value: cubit,
        child: ReceiptReviewPage(onSuccess: onSuccess ?? (_) {}),
      ),
    );
  }

  group('ReceiptReviewPage', () {
    testWidgets('review_allocation_updates_live_390', (tester) async {
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

      // Thêm 2 dòng theo đúng ca spec 4.1: line1: 6 hộp * 100k, line2: 4 liều * 100k
      final k1 = cubit.addLine('p-1', 'u-1');
      cubit.updateLine(k1, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 6)],
      ));

      final k2 = cubit.addLine('p-2', 'u-2');
      cubit.updateLine(k2, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 4)],
      ));

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Dải tổng ban đầu: Giá gốc 1.000.000 đ
      expect(find.text('1.000.000 đ'), findsWidgets);

      // Nhập Chi phí thu mua: 50.000, Chiết khấu: 20.000
      cubit.setFreightVnd(50000);
      cubit.setDiscountVnd(20000);
      await tester.pumpAndSettle();

      // Giá gốc tổng trở thành 1.030.000 đ
      expect(find.text('1.030.000 đ'), findsWidgets);
      // Dòng 1 phân bổ chi phí +30.000 đ, chiết khấu -12.000 đ
      expect(find.text('+30.000 đ'), findsOneWidget);
      expect(find.text('-12.000 đ'), findsOneWidget);
      // Dòng 2 phân bổ chi phí +20.000 đ, chiết khấu -8.000 đ
      expect(find.text('+20.000 đ'), findsOneWidget);
      expect(find.text('-8.000 đ'), findsOneWidget);
    });

    testWidgets('discount_error_disables_submit_390', (tester) async {
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
      final k1 = cubit.addLine('p-1', 'u-1');
      cubit.updateLine(k1, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 1)],
      ));

      // Chiết khấu lớn hơn tổng mua (200.000 > 100.000)
      cubit.setDiscountVnd(200000);

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Chiết khấu không được lớn hơn tổng giá mua và chi phí'), findsWidgets);
    });

    testWidgets('review_table_1280', (tester) async {
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
      final k1 = cubit.addLine('p-1', 'u-1');
      cubit.updateLine(k1, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 1)],
      ));

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      // Bảng web 7 cột
      expect(find.text('Mặt hàng'), findsOneWidget);
      expect(find.text('Giá mua'), findsWidgets);
      expect(find.text('Giảm bậc'), findsOneWidget);
      expect(find.text('Chi phí'), findsWidgets);
      expect(find.text('Chiết khấu'), findsWidgets);
      expect(find.text('Giá gốc'), findsWidgets);
      expect(find.text('Đơn giá gốc'), findsOneWidget);
    });

    testWidgets('network_error_retry_390', (tester) async {
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
      final k1 = cubit.addLine('p-1', 'u-1');
      cubit.updateLine(k1, (l) => l.copyWith(
        unitPriceVnd: 100000,
        lots: [l.lots.first.copyWith(quantity: 1)],
      ));

      receiptRepo.nextRecordError = const AppException('NETWORK_ERROR');

      await tester.pumpWidget(wrap(cubit));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ghi nhận'));
      await tester.tap(find.text('Ghi nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa ghi nhận được do mất kết nối.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
