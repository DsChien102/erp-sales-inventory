import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_state.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_list_page.dart';

class _FakeReceiptRepo extends Fake implements GoodsReceiptRepository {
  List<ReceiptListRow> rows = [];
  ReceiptFormOptions options = const ReceiptFormOptions(
    warehouseName: 'Kho chính',
    today: '2026-11-10',
    suppliers: [
      ReceiptSupplierOption(id: 's-1', name: 'Công ty Á Châu', code: 'AC', isSystem: false),
      ReceiptSupplierOption(id: 's-2', name: 'Dược Nam Hà', code: 'NH', isSystem: false),
    ],
    products: [],
    lots: [],
  );

  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async {
    if (supplierId != null) {
      return rows.where((r) => r.supplierId == supplierId).toList();
    }
    return rows;
  }

  @override
  Future<ReceiptFormOptions> formOptions() async => options;
}

void main() {
  late _FakeReceiptRepo repository;

  final sampleRows = [
    const ReceiptListRow(
      receiptId: 'rc-1',
      receiptNo: 'PN-261110-01',
      supplierId: 's-1',
      supplierName: 'Công ty Á Châu',
      supplierIsSystem: false,
      supplierDocNo: 'HD-001',
      businessDate: '2026-11-10',
      lineCount: 2,
      lotCount: 3,
      landedTotalVnd: 5500000,
      createdByName: 'Nguyễn Văn Kho',
      createdAt: '2026-11-10T08:00:00Z',
    ),
    const ReceiptListRow(
      receiptId: 'rc-2',
      receiptNo: 'PN-261110-02',
      supplierId: 's-2',
      supplierName: 'Dược Nam Hà',
      supplierIsSystem: false,
      supplierDocNo: null,
      businessDate: '2026-11-10',
      lineCount: 1,
      lotCount: 1,
      landedTotalVnd: 1200000,
      createdByName: 'Trần Thị Thu',
      createdAt: '2026-11-10T09:00:00Z',
    ),
  ];

  setUp(() {
    repository = _FakeReceiptRepo();
    repository.rows = sampleRows;
  });

  Widget buildApp(ReceiptListCubit cubit, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: BlocProvider.value(
          value: cubit,
          child: ReceiptListPage(
            onOpenDetail: (_) {},
            onNewReceipt: () {},
          ),
        ),
      ),
    );
  }

  group('ReceiptListPage', () {
    testWidgets('list_cards_390', (tester) async {
      final cubit = ReceiptListCubit(repository: repository);
      await cubit.load();

      await tester.pumpWidget(buildApp(cubit, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      // Thẻ 1: 4 hàng chữ
      expect(find.text('PN-261110-01 · Công ty Á Châu'), findsOneWidget);
      expect(find.text('2 dòng (3 lô)'), findsOneWidget);
      expect(find.text('5.500.000 đ'), findsOneWidget);
      expect(find.text('2026-11-10 · Nguyễn Văn Kho'), findsOneWidget);

      // Thẻ 2
      expect(find.text('PN-261110-02 · Dược Nam Hà'), findsOneWidget);
      expect(find.text('1 dòng (1 lô)'), findsOneWidget);
      expect(find.text('1.200.000 đ'), findsOneWidget);
      expect(find.text('2026-11-10 · Trần Thị Thu'), findsOneWidget);
    });

    testWidgets('list_table_1280', (tester) async {
      final cubit = ReceiptListCubit(repository: repository);
      await cubit.load();

      await tester.pumpWidget(buildApp(cubit, size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      // Bảng rộng: 6 cột
      expect(find.text('Số phiếu'), findsOneWidget);
      expect(find.text('Nhà cung cấp'), findsOneWidget);
      expect(find.text('Dòng / Lô'), findsOneWidget);
      expect(find.text('Tổng giá gốc'), findsOneWidget);
      expect(find.text('Ngày nhận'), findsOneWidget);
      expect(find.text('Người nhận'), findsOneWidget);
      expect(find.text('PN-261110-01'), findsOneWidget);
    });

    testWidgets('list_search_filters', (tester) async {
      final cubit = ReceiptListCubit(repository: repository);
      await cubit.load();

      await tester.pumpWidget(buildApp(cubit));
      await tester.pumpAndSettle();

      cubit.setQuery('Nam Hà');
      await tester.pumpAndSettle();

      expect(find.text('PN-261110-02 · Dược Nam Hà'), findsOneWidget);
      expect(find.text('PN-261110-01 · Công ty Á Châu'), findsNothing);
    });

    testWidgets('list_empty_390', (tester) async {
      repository.rows = [];
      final cubit = ReceiptListCubit(repository: repository);
      await cubit.load();

      await tester.pumpWidget(buildApp(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có phiếu nhận hàng nào.'), findsOneWidget);
    });

    testWidgets('list_supplier_filter_subtitle', (tester) async {
      final cubit = ReceiptListCubit(repository: repository, initialSupplierId: 's-1');
      await cubit.load();

      await tester.pumpWidget(buildApp(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Nhà cung cấp: Công ty Á Châu'), findsOneWidget);
    });

    test('cubit_set_supplier_reloads_from_repository', () async {
      final cubit = ReceiptListCubit(repository: repository, initialSupplierId: 's-1');
      await cubit.load();
      expect(cubit.state.supplierId, 's-1');

      // Vào từ màn NCC: server chỉ trả phiếu của s-1.
      expect(cubit.state.all.map((r) => r.supplierId).toSet(), {'s-1'});

      await cubit.setSupplier(null);
      expect(cubit.state.supplierId, isNull);
      expect(cubit.state.status, ReceiptListStatus.ready);
      // "Tất cả NCC" phải tải lại từ server ⇒ có phiếu của mọi NCC.
      expect(cubit.state.all.map((r) => r.supplierId).toSet(), {'s-1', 's-2'});

      await cubit.setSupplier('s-2');
      expect(cubit.state.visible.map((r) => r.receiptId), ['rc-2']);
    });
  });
}

