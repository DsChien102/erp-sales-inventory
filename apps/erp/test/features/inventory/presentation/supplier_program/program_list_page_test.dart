import 'dart:io';

import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-2b/$fileName';
}

class MockSupplierProgramRepository extends Mock
    implements SupplierProgramRepository {}

void main() {
  late MockSupplierProgramRepository mockRepository;

  final rowTier = ProgramRow(
    id: 'prog-1',
    name: 'Nobivac bậc SL',
    supplierId: 'sup-1',
    supplierName: 'Cty Thú Y Á Châu',
    kind: ProgramKind.tierDiscount,
    status: ProgramStatus.active,
    startedOn: DateTime(2026, 11, 10),
    productIds: const ['prod-1'],
    productCount: 1,
    commonUom: 'hộp',
    tiers: const [
      ProgramTier(minQty: 100, discountPercent: 3),
      ProgramTier(minQty: 300, discountPercent: 5),
    ],
    progressQty: 0,
  );

  final rowVolumeReached = ProgramRow(
    id: 'prog-2',
    name: 'Mốc 1.000 hộp Q4',
    supplierId: 'sup-2',
    supplierName: 'NCC A',
    kind: ProgramKind.volumeRebate,
    status: ProgramStatus.reached,
    startedOn: DateTime(2026, 10, 1),
    productIds: const ['prod-1'],
    productCount: 1,
    commonUom: 'hộp',
    tiers: const [],
    targetQty: 1000,
    rebatePercent: 5,
    progressQty: 1000,
  );

  final rowBuyXEnded = ProgramRow(
    id: 'prog-3',
    name: 'Mua 10 tặng 1',
    supplierId: 'sup-1',
    supplierName: 'Cty Thú Y Á Châu',
    kind: ProgramKind.buyXGetY,
    status: ProgramStatus.ended,
    startedOn: DateTime(2026, 9, 1),
    productIds: const ['prod-2'],
    productCount: 1,
    commonUom: 'hộp',
    tiers: const [],
    buyQty: 10,
    freeQty: 1,
    progressQty: 0,
  );

  const sampleOptions = ProgramFormOptions(
    suppliers: [
      SupplierOption(partnerId: 'sup-1', displayName: 'Cty Thú Y Á Châu'),
      SupplierOption(partnerId: 'sup-2', displayName: 'NCC A'),
    ],
    products: [
      ProductOption(
        productId: 'prod-1',
        name: 'Nobivac DHPPi',
        code: 'NOBI-01',
        baseUnitId: 'u-1',
        baseUom: 'hộp',
      ),
      ProductOption(
        productId: 'prod-2',
        name: 'Nobivac Rabies',
        code: 'NOBI-02',
        baseUnitId: 'u-1',
        baseUom: 'hộp',
      ),
    ],
  );

  setUp(() async {
    await GetIt.I.reset();
    mockRepository = MockSupplierProgramRepository();
    GetIt.I.registerSingleton<SupplierProgramRepository>(mockRepository);

    when(() => mockRepository.list()).thenAnswer(
      (_) async => [rowTier, rowVolumeReached, rowBuyXEnded],
    );
    when(() => mockRepository.formOptions())
        .thenAnswer((_) async => sampleOptions);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    String? initialSupplierId,
    ProgramStatus? initialStatus,
    ValueChanged<String>? onRoutePushed,
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs',
      routes: [
        GoRoute(
          path: '/warehouse',
          builder: (_, _) => const Scaffold(body: Text('Hub Kho')),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs',
          builder: (_, _) => ProgramListPage(
            initialSupplierId: initialSupplierId,
            initialStatus: initialStatus,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/new',
          builder: (_, state) {
            onRoutePushed?.call(state.uri.toString());
            return const Scaffold(body: Text('Màn Tạo'));
          },
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) {
            onRoutePushed?.call(state.uri.toString());
            return const Scaffold(body: Text('Màn Chi Tiết'));
          },
        ),
      ],
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
    );
  }

  group('ProgramListPage', () {
    testWidgets('list_ready_390', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Chương trình NCC'), findsOneWidget);
      expect(find.text('Đang chạy'), findsWidgets);
      expect(find.text(' 1'), findsNWidgets(3));
      expect(find.text('Đạt mốc'), findsOneWidget);
      expect(find.text('Đã ghi nhận'), findsOneWidget);
      expect(find.text('Kết thúc'), findsOneWidget);
      expect(
        find.text('Từ 100 hộp giảm 3% · từ 300 giảm 5%'),
        findsOneWidget,
      );
      expect(find.text('Tạo chương trình'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P1-READY-390.png')),
      );
    });

    testWidgets('chip_reached_shows_progress_390', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đạt mốc'));
      await tester.pumpAndSettle();

      expect(find.text('Mốc 1.000 hộp Q4'), findsOneWidget);
      expect(find.text('1.000 / 1.000 hộp'), findsOneWidget);
      expect(find.byType(VProgress), findsOneWidget);
    });

    testWidgets('supplier_filter_sheet_390', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('NCC: Tất cả'));
      await tester.pumpAndSettle();

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('NCC A'), findsOneWidget);

      await tester.tap(find.text('NCC A'));
      await tester.pumpAndSettle();

      expect(find.textContaining('NCC: NCC A'), findsOneWidget);
    });

    testWidgets('filter_empty_clear_390', (tester) async {
      await tester.pumpWidget(buildApp(initialSupplierId: 'sup-2'));
      await tester.pumpAndSettle();

      expect(find.text('Không có chương trình phù hợp'), findsOneWidget);
      expect(find.text('Thử bộ lọc khác.'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('Nobivac bậc SL'), findsOneWidget);
    });

    testWidgets('empty_390', (tester) async {
      when(() => mockRepository.list()).thenAnswer((_) async => const []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Chưa có chương trình nhà cung cấp'), findsOneWidget);
      expect(
        find.text('Khai báo ưu đãi của nhà cung cấp để áp khi nhận hàng.'),
        findsOneWidget,
      );
      expect(find.text('Tạo chương trình'), findsWidgets);
    });

    testWidgets('load_error_retry_390', (tester) async {
      var calls = 0;
      when(() => mockRepository.list()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('err');
        return [rowTier];
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Không tải được danh sách'), findsOneWidget);
      expect(find.text('Kiểm tra kết nối rồi thử lại.'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Nobivac bậc SL'), findsOneWidget);
    });

    testWidgets('list_ready_1280', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      final table = tester.widget<VTable>(find.byType(VTable));
      expect(
        table.headers.map((h) => h.title).toList(),
        ['Tên', 'Nhà cung cấp', 'Loại', 'Ưu đãi', 'Trạng thái'],
      );
      expect(find.text('Tạo chương trình'), findsOneWidget);
      expect(find.byType(InventoryFooter), findsNothing);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P1-READY-1280.png')),
      );
    });

    testWidgets('row_tap_opens_detail', (tester) async {
      String? pushed;
      await tester.pumpWidget(buildApp(onRoutePushed: (r) => pushed = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nobivac bậc SL'));
      await tester.pumpAndSettle();

      expect(pushed, '/warehouse/supplier-programs/prog-1');
    });

    testWidgets('create_tap_opens_form', (tester) async {
      String? pushed;
      await tester.pumpWidget(buildApp(onRoutePushed: (r) => pushed = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo chương trình'));
      await tester.pumpAndSettle();

      expect(pushed, '/warehouse/supplier-programs/new');
    });

    testWidgets('list_initial_status_reached', (tester) async {
      await tester.pumpWidget(
        buildApp(initialStatus: ProgramStatus.reached),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mốc 1.000 hộp Q4'), findsOneWidget);
      expect(find.text('Nobivac bậc SL'), findsNothing);
    });
  });
}
