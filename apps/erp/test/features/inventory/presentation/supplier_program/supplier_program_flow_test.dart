import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_area_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/supplier_program/supplier_program_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _StatefulSupplierProgramRepository implements SupplierProgramRepository {
  final Map<String, ProgramDetail> _programs = {};
  int _seq = 0;

  static const _suppliers = [
    SupplierOption(partnerId: 'sup-1', displayName: 'NCC A'),
  ];

  static const _products = [
    ProductOption(
      productId: 'prod-1',
      name: 'Nobivac DHPPi',
      code: 'NBV-01',
      baseUnitId: 'unit-1',
      baseUom: 'hộp',
    ),
  ];

  @override
  Future<List<ProgramRow>> list() async =>
      _programs.values.map((d) => d.row).toList();

  @override
  Future<ProgramDetail> get(String id) async => _programs[id]!;

  @override
  Future<ProgramFormOptions> formOptions() async => const ProgramFormOptions(
        suppliers: _suppliers,
        products: _products,
      );

  @override
  Future<({String id, int revision})> create({
    required String idempotencyKey,
    required ProgramPayload payload,
  }) async {
    _seq++;
    final id = 'prog-$_seq';
    final supplier = _suppliers.firstWhere(
      (s) => s.partnerId == payload.supplierId,
      orElse: () => _suppliers.first,
    );
    final selectedProducts = _products
        .where((p) => payload.productIds.contains(p.productId))
        .map(
          (p) => ProgramProduct(
            productId: p.productId,
            name: p.name,
            code: p.code,
            baseUom: p.baseUom,
          ),
        )
        .toList();
    final commonUom = selectedProducts.isNotEmpty
        ? selectedProducts.first.baseUom
        : null;

    final row = ProgramRow(
      id: id,
      name: payload.name,
      supplierId: supplier.partnerId,
      supplierName: supplier.displayName,
      kind: payload.kind ?? ProgramKind.tierDiscount,
      status: ProgramStatus.active,
      startedOn: payload.startedOn,
      productIds: payload.productIds,
      productCount: payload.productIds.length,
      commonUom: commonUom,
      tiers: payload.tiers,
      buyQty: payload.buyQty,
      freeQty: payload.freeQty,
      targetQty: payload.targetQty,
      rebatePercent: payload.rebatePercent,
      progressQty: 0,
    );

    _programs[id] = ProgramDetail(
      row: row,
      note: payload.note,
      revision: 1,
      isLocked: false,
      products: selectedProducts,
      receipts: const [],
      baseAmountVnd: 0,
    );
    return (id: id, revision: 1);
  }

  @override
  Future<({String id, int revision})> update({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
    required ProgramPayload payload,
  }) async {
    final prev = _programs[id]!;
    final nextRev = expectedRevision + 1;
    return (id: prev.row.id, revision: nextRev);
  }

  @override
  Future<int> end({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
  }) async {
    final prev = _programs[id]!;
    final nextRev = expectedRevision + 1;
    final cur = prev.row;
    _programs[id] = ProgramDetail(
      row: ProgramRow(
        id: cur.id,
        name: cur.name,
        supplierId: cur.supplierId,
        supplierName: cur.supplierName,
        kind: cur.kind,
        status: ProgramStatus.ended,
        startedOn: cur.startedOn,
        productIds: cur.productIds,
        productCount: cur.productCount,
        commonUom: cur.commonUom,
        tiers: cur.tiers,
        buyQty: cur.buyQty,
        freeQty: cur.freeQty,
        targetQty: cur.targetQty,
        rebatePercent: cur.rebatePercent,
        progressQty: cur.progressQty,
      ),
      note: prev.note,
      revision: nextRev,
      isLocked: prev.isLocked,
      endedAt: DateTime.utc(2026, 11, 15),
      products: prev.products,
      receipts: prev.receipts,
      baseAmountVnd: prev.baseAmountVnd,
    );
    return nextRev;
  }

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      [];
}

void main() {
  late _StatefulSupplierProgramRepository repo;

  setUp(() async {
    await getIt.reset();
    repo = _StatefulSupplierProgramRepository();
    getIt.registerSingleton<SupplierProgramRepository>(repo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('supplier_program_end_to_end_flow_390', (tester) async {
    const size = Size(390, 844);
    useInventoryTestSurface(size);

    final router = GoRouter(
      initialLocation: '/warehouse/area/valuation',
      routes: [
        GoRoute(
          path: '/warehouse/area/valuation',
          builder: (_, _) => const WarehouseAreaPage(
            area: WarehouseArea.valuation,
            isOwner: true,
          ),
        ),
        ...supplierProgramRoutes(),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Hub khu Giá trị -> P1 rỗng
    expect(find.text('Chương trình nhà cung cấp'), findsOneWidget);
    await tester.tap(find.text('Chương trình nhà cung cấp'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có chương trình nhà cung cấp'), findsOneWidget);

    // 2. Bấm "Tạo chương trình" -> P2
    await tester.tap(find.text('Tạo chương trình').first);
    await tester.pumpAndSettle();

    // Chọn NCC
    await tester.tap(find.text('Chọn nhà cung cấp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NCC A').last);
    await tester.pumpAndSettle();

    // Chọn loại "Chiết khấu đạt mốc số lượng tích luỹ"
    await tester.tap(find.text('Chiết khấu đạt mốc số lượng tích luỹ'));
    await tester.pumpAndSettle();

    // Nhập tên chương trình
    final nameField = find.descendant(
      of: find.byType(VTextField, skipOffstage: false).first,
      matching: find.byType(EditableText, skipOffstage: false),
    );
    await tester.enterText(nameField, 'Mốc 1.000 hộp Q4');
    await tester.pumpAndSettle();

    // Chọn 1 sản phẩm
    await tester.ensureVisible(find.text('Chọn sản phẩm'));
    await tester.tap(find.text('Chọn sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nobivac DHPPi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    // Nhập mốc 1000, chiết khấu 5%
    final numberFields = find.byType(VNumberField, skipOffstage: false);
    final targetInput = find.descendant(
      of: numberFields.at(0),
      matching: find.byType(EditableText, skipOffstage: false),
    );
    final pctInput = find.descendant(
      of: numberFields.at(1),
      matching: find.byType(EditableText, skipOffstage: false),
    );
    await tester.enterText(targetInput, '1000');
    await tester.pumpAndSettle();
    await tester.enterText(pctInput, '5');
    await tester.pumpAndSettle();

    // Bấm "Lưu" -> P3 có "0 / 1.000 hộp"
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 1.000 hộp'), findsOneWidget);

    // Quay về P1 thấy dòng, chip "Đang chạy 1"
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Đang chạy'), findsWidgets);
    expect(find.text(' 1'), findsOneWidget);
    expect(find.text('Mốc 1.000 hộp Q4'), findsOneWidget);

    // Mở P3 -> "Kết thúc chương trình" -> xác nhận
    await tester.tap(find.text('Mốc 1.000 hộp Q4'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kết thúc chương trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc'));
    await tester.pumpAndSettle();

    // Quay về P1 thấy chip "Kết thúc 1"
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Kết thúc'), findsOneWidget);
    expect(find.text(' 1'), findsOneWidget);
  });
}
