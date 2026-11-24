import 'dart:io';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_form_page.dart';
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

class FakeProgramPayload extends Fake implements ProgramPayload {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProgramPayload());
  });

  late MockSupplierProgramRepository mockRepository;

  const sampleOptions = ProgramFormOptions(
    suppliers: [
      SupplierOption(partnerId: 'sup-1', displayName: 'Cty Thú Y Á Châu'),
      SupplierOption(
        partnerId: 'sup-overlap',
        displayName: 'NCC Đang Chạy',
        activeProgram: (id: 'prog-active', name: 'Nobivac bậc SL'),
      ),
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
        name: 'Amox',
        code: 'AMOX-01',
        baseUnitId: 'u-2',
        baseUom: 'chai',
      ),
    ],
  );

  final sampleDetail = ProgramDetail(
    row: ProgramRow(
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
      ],
      progressQty: 0,
    ),
    revision: 1,
    isLocked: false,
    products: const [
      ProgramProduct(
        productId: 'prod-1',
        name: 'Nobivac DHPPi',
        code: 'NOBI-01',
        baseUom: 'hộp',
      ),
    ],
    receipts: const [],
    baseAmountVnd: 0,
  );

  setUp(() async {
    await GetIt.I.reset();
    mockRepository = MockSupplierProgramRepository();
    GetIt.I.registerSingleton<SupplierProgramRepository>(mockRepository);
    when(() => mockRepository.formOptions())
        .thenAnswer((_) async => sampleOptions);
    when(() => mockRepository.get('prog-1'))
        .thenAnswer((_) async => sampleDetail);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildCreateApp({
    Size size = const Size(390, 844),
    String? supplierId,
    String? productId,
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs/new',
      routes: [
        GoRoute(
          path: '/warehouse/supplier-programs/new',
          builder: (_, _) => ProgramFormPage.create(
            supplierId: supplierId,
            productId: productId,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) => Scaffold(
            body: Text('Chi tiết ${state.pathParameters['programId']}'),
          ),
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

  Widget buildEditApp({
    Size size = const Size(390, 844),
    String programId = 'prog-1',
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs/$programId/edit',
      routes: [
        GoRoute(
          path: '/warehouse/supplier-programs/:programId/edit',
          builder: (_, state) => ProgramFormPage.edit(
            programId: state.pathParameters['programId']!,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) => Scaffold(
            body: Text('Chi tiết ${state.pathParameters['programId']}'),
          ),
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

  group('ProgramFormPage', () {
    testWidgets('create_default_tier_kind_390', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      expect(find.text('Tạo chương trình'), findsOneWidget);
      expect(find.text('Giảm giá theo bậc số lượng'), findsOneWidget);
      expect(find.text('Mua X tặng Y'), findsOneWidget);
      expect(
        find.text('Chiết khấu đạt mốc số lượng tích luỹ'),
        findsOneWidget,
      );
      expect(find.text('Từ'), findsOneWidget);
      expect(find.text('giảm'), findsOneWidget);
      expect(find.text('Thêm bậc'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P2-CREATE-390.png')),
      );
    });

    testWidgets('walk_in_not_in_supplier_options', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      expect(find.text('Mua lẻ / khác'), findsNothing);
    });

    testWidgets('overlap_banner_disables_save_390', (tester) async {
      await tester.pumpWidget(buildCreateApp(supplierId: 'sup-overlap'));
      await tester.pumpAndSettle();

      expect(
        find.text('NCC này đang có chương trình "Nobivac bậc SL".'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Kết thúc chương trình đó trước khi tạo chương trình mới.',
        ),
        findsOneWidget,
      );
      expect(find.text('Xem chương trình'), findsOneWidget);
    });

    testWidgets('kind_switch_shows_kind_fields_390', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      final minField = find.descendant(
        of: find.byType(VNumberField, skipOffstage: false).first,
        matching: find.byType(EditableText, skipOffstage: false),
      );
      await tester.enterText(minField, '100');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mua X tặng Y'));
      await tester.pumpAndSettle();

      expect(find.text('Mua'), findsOneWidget);
      expect(find.text('tặng'), findsOneWidget);
      expect(find.text('Thêm bậc'), findsNothing);

      await tester.tap(find.text('Giảm giá theo bậc số lượng'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm bậc'), findsOneWidget);
      final restoredText = tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(VNumberField, skipOffstage: false).first,
              matching: find.byType(EditableText, skipOffstage: false),
            ),
          )
          .controller
          .text;
      expect(restoredText, '100');
    });

    testWidgets('add_tier_hidden_at_five', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(find.text('Thêm bậc'));
        await tester.tap(find.text('Thêm bậc'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Thêm bậc'), findsNothing);
    });

    testWidgets('save_shows_errors_and_scrolls', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(VFieldError, 'Chọn nhà cung cấp'), findsOneWidget);
      expect(find.text('Nhập tên chương trình'), findsOneWidget);
      expect(find.text('Chọn ít nhất một sản phẩm'), findsOneWidget);
    });

    testWidgets('volume_uom_hint_text', (tester) async {
      await tester.pumpWidget(buildCreateApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chiết khấu đạt mốc số lượng tích luỹ'));
      await tester.pumpAndSettle();

      expect(
        find.text('Số lượng vượt mốc vẫn tính vào căn cứ chiết khấu.'),
        findsOneWidget,
      );
    });

    testWidgets('edit_supplier_kind_readonly_390', (tester) async {
      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      expect(find.text('Sửa chương trình'), findsOneWidget);
      expect(find.byType(VSelect<String>), findsNothing);
      expect(find.byType(VChoiceList<ProgramKind>), findsNothing);
      expect(find.text('Cty Thú Y Á Châu'), findsOneWidget);
      expect(find.text('Giảm giá theo bậc số lượng'), findsOneWidget);
    });

    testWidgets('locked_shows_end_only_390', (tester) async {
      when(() => mockRepository.get('prog-1')).thenAnswer(
        (_) async => ProgramDetail(
          row: sampleDetail.row,
          revision: 1,
          isLocked: true,
          products: sampleDetail.products,
          receipts: const [],
          baseAmountVnd: 0,
        ),
      );

      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Chương trình đã có phiếu nhận gắn nên không sửa được tham số.',
        ),
        findsOneWidget,
      );
      expect(find.text('Kết thúc chương trình'), findsOneWidget);
      expect(find.text('Lưu'), findsNothing);
    });

    testWidgets('locked_status_ended_message_390', (tester) async {
      final endedRow = ProgramRow(
        id: sampleDetail.row.id,
        name: sampleDetail.row.name,
        supplierId: sampleDetail.row.supplierId,
        supplierName: sampleDetail.row.supplierName,
        kind: sampleDetail.row.kind,
        status: ProgramStatus.ended,
        startedOn: sampleDetail.row.startedOn,
        productIds: sampleDetail.row.productIds,
        productCount: sampleDetail.row.productCount,
        commonUom: sampleDetail.row.commonUom,
        tiers: sampleDetail.row.tiers,
        progressQty: sampleDetail.row.progressQty,
      );
      when(() => mockRepository.get('prog-1')).thenAnswer(
        (_) async => ProgramDetail(
          row: endedRow,
          revision: 1,
          isLocked: true,
          products: sampleDetail.products,
          receipts: const [],
          baseAmountVnd: 0,
        ),
      );

      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Chương trình đã kết thúc nên không sửa được.'),
        findsOneWidget,
      );
      expect(find.text('Kết thúc chương trình'), findsNothing);
    });

    testWidgets('locked_end_error_shown_390', (tester) async {
      when(() => mockRepository.get('prog-1')).thenAnswer(
        (_) async => ProgramDetail(
          row: sampleDetail.row,
          revision: 1,
          isLocked: true,
          products: sampleDetail.products,
          receipts: const [],
          baseAmountVnd: 0,
        ),
      );
      when(
        () => mockRepository.end(
          idempotencyKey: any(named: 'idempotencyKey'),
          id: 'prog-1',
          expectedRevision: 1,
        ),
      ).thenThrow(const AppException(InventoryErrorCode.programLocked));

      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết thúc chương trình'));
      await tester.pumpAndSettle();

      // In confirmation bottom sheet
      expect(find.text('Kết thúc'), findsOneWidget);
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is VBanner && w.tone == VComponentTone.danger,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Chương trình đã có phiếu nhận'),
        findsWidgets,
      );
    });

    testWidgets('locked_end_conflict_reload_390', (tester) async {
      when(() => mockRepository.get('prog-1')).thenAnswer(
        (_) async => ProgramDetail(
          row: sampleDetail.row,
          revision: 1,
          isLocked: true,
          products: sampleDetail.products,
          receipts: const [],
          baseAmountVnd: 0,
        ),
      );
      when(
        () => mockRepository.end(
          idempotencyKey: any(named: 'idempotencyKey'),
          id: 'prog-1',
          expectedRevision: 1,
        ),
      ).thenThrow(const AppException(InventoryErrorCode.versionConflict));

      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết thúc chương trình'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryStale), findsOneWidget);
      expect(find.text('Tải lại'), findsOneWidget);

      await tester.tap(find.text('Tải lại'));
      await tester.pumpAndSettle();
      verify(() => mockRepository.get('prog-1')).called(greaterThan(1));
    });

    testWidgets('version_conflict_reload_390', (tester) async {
      when(
        () => mockRepository.update(
          idempotencyKey: any(named: 'idempotencyKey'),
          id: 'prog-1',
          expectedRevision: 1,
          payload: any(named: 'payload'),
        ),
      ).thenThrow(const AppException(InventoryErrorCode.versionConflict));

      await tester.pumpWidget(buildEditApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Chương trình đã được sửa ở nơi khác. Tải lại để xem bản mới.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tải lại'), findsOneWidget);
    });

    testWidgets('submit_overlap_message_390', (tester) async {
      when(
        () => mockRepository.create(
          idempotencyKey: any(named: 'idempotencyKey'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(const AppException(InventoryErrorCode.programOverlap));

      await tester.pumpWidget(buildCreateApp(supplierId: 'sup-1'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(VTextField).first, 'Bậc mới');
      await tester.pump();

      // Pick product
      await tester.ensureVisible(find.text('Chọn sản phẩm'));
      await tester.tap(find.text('Chọn sản phẩm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();

      // Enter tier
      final numFields = find.byType(VNumberField);
      await tester.enterText(numFields.at(0), '100');
      await tester.enterText(numFields.at(1), '3');
      await tester.pump();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'NCC này đang có chương trình khác đang chạy. Kết thúc chương trình đó trước khi tạo chương trình mới.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('form_1280_centered_max_720', (tester) async {
      await tester.pumpWidget(buildCreateApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(
        scaffold.contentMaxWidth.resolve(VBreakpoint.desktop),
        720,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P2-CREATE-1280.png')),
      );
    });

    testWidgets('form_prefills_product_390', (tester) async {
      await tester.pumpWidget(
        buildCreateApp(supplierId: 'sup-1', productId: 'prod-1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nobivac DHPPi'), findsOneWidget);
    });
  });
}
