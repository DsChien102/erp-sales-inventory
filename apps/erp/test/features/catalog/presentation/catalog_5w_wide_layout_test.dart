// Plan 5-W, Task 5 — bố cục web 2 cột (1280 × 800), W4/W5/W6/W10.
import 'dart:async';

import 'package:erp/core/router/app_router.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/presentation/pages/product_catalog_tab_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:erp/features/catalog/presentation/widgets/image_picker/product_image_add_sheet.dart';
import 'package:erp/features/catalog/presentation/widgets/product_catalog_filter_chips.dart';
import 'package:erp/features/catalog/presentation/widgets/product_list_filter.dart';
import 'package:erp/features/catalog/presentation/widgets/product_list_item_tile.dart';
import 'package:erp/features/dashboard/presentation/store_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../catalog_e2e_harness.dart';
import '../support/fake_catalog_backend.dart';
import '../support/catalog_router_harness.dart';
import '../support/fake_catalog_repositories.dart';
import '../support/fake_catalog_scenario.dart';

const _wide = Size(1280, 800);
const _pccKey = Key('wgt_e01_u02_fr01_01');
const _emptyDetail = 'Chọn một sản phẩm để xem chi tiết.';

ProductListItemTile _tile(WidgetTester tester, String productId) => tester
    .widgetList<ProductListItemTile>(find.byType(ProductListItemTile))
    .firstWhere((t) => t.item.id == productId);

Future<void> _openDangerSection(WidgetTester tester) async {
  final dangerSection = find.byKey(const Key('btn_product_lifecycle_danger_toggle'));
  await tester.scrollUntilVisible(
    dangerSection,
    300,
    scrollable: find.descendant(
      of: find.byType(ProductControlCenterPage),
      matching: find.byType(Scrollable),
    ).first,
  );
  await tester.tap(dangerSection);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _PccCompleterRepository extends FakeProductRepository {
  _PccCompleterRepository({required super.backend});

  final Completer<ProductControlCenterDto> product2Completer = Completer<ProductControlCenterDto>();

  @override
  Future<ProductControlCenterDto> getControlCenter(String productId) {
    if (productId == 'product-2') {
      return product2Completer.future;
    }
    return super.getControlCenter(productId);
  }
}

class _RecordingProductRepository extends FakeProductRepository {
  _RecordingProductRepository({required super.backend});

  final List<ProductSearchCriteria?> recordedCriteria = [];

  @override
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) {
    recordedCriteria.add(criteria);
    return super.search(criteria: criteria, limit: limit, offset: offset);
  }
}

void main() {
  setUp(setUpCatalogRouterTest);
  tearDown(tearDownCatalogRouterTest);

  group('5-W Task 5 — web 2 cột (1280 × 800)', () {
    testWidgets('split_empty_detail: danh sách bên trái, ô phải trống với chuỗi Q7', (tester) async {
      await pumpCatalogApp(tester, size: _wide);

      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(find.text(_emptyDetail), findsOneWidget);
      expect(find.byType(ProductControlCenterPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_select_updates_url_and_selection: chọn dòng đổi URL và chọn thẻ', (tester) async {
      await pumpCatalogApp(tester, size: _wide);

      await tester.tap(find.text('Amoxicillin 500mg').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(catalogCurrentPath, '/products/items/product-1');
      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(find.byKey(_pccKey), findsOneWidget);
      expect(find.text(_emptyDetail), findsNothing);
      expect(_tile(tester, 'product-1').isSelected, isTrue);
      expect(_tile(tester, 'product-2').isSelected, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_deep_link_selects_row: mở thẳng URL hiện 2 cột và chọn dòng', (tester) async {
      await pumpCatalogApp(tester, size: _wide, location: '/products/items/product-1');

      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(find.byKey(_pccKey), findsOneWidget);
      expect(_tile(tester, 'product-1').isSelected, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_switch_a_to_b: đổi từ sản phẩm A sang B không giữ dữ liệu A khi B đang tải', (tester) async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.searchWithReadiness);
      final repo = _PccCompleterRepository(backend: backend);

      await pumpCatalogApp(
        tester,
        productRepository: repo,
        size: _wide,
        location: '/products/items/product-1',
      );
      expect(find.text('Amoxicillin 500mg'), findsWidgets);

      await tester.tap(find.text('Paracetamol 500mg').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(catalogCurrentPath, '/products/items/product-2');
      expect(
        find.descendant(
          of: find.byType(ProductControlCenterPage),
          matching: find.text('Amoxicillin 500mg'),
        ),
        findsNothing,
      );

      repo.product2Completer.complete(backend.handleGetControlCenter('product-2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Paracetamol 500mg'), findsWidgets);
      expect(_tile(tester, 'product-2').isSelected, isTrue);
      expect(_tile(tester, 'product-1').isSelected, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_no_back_button: PCC trên split không có nút back', (tester) async {
      await pumpCatalogApp(tester, size: _wide, location: '/products/items/product-1');

      final backButtonFinder = find.descendant(
        of: find.byType(ProductControlCenterPage),
        matching: find.byWidgetPredicate(
          (w) => w is IconButton && w.icon is VIcon && (w.icon as VIcon).icon == VIcons.arrowBack,
        ),
      );
      expect(backButtonFinder, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_select_keeps_filter_chip: chọn chip rồi chọn sản phẩm giữ chip lọc', (tester) async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.searchWithReadiness);
      final repo = _RecordingProductRepository(backend: backend);

      await pumpCatalogApp(
        tester,
        productRepository: repo,
        scenario: FakeCatalogScenario.searchWithReadiness,
        size: _wide,
      );

      // Bấm chip Ngừng KD
      final inactiveChipFinder = find.byWidgetPredicate(
        (w) => w is VChip && w.label.contains('Ngừng KD'),
      );
      await tester.ensureVisible(inactiveChipFinder);
      await tester.tap(inactiveChipFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bấm một sản phẩm trong danh sách lọc
      expect(find.byType(ProductListItemTile), findsWidgets);
      await tester.tap(find.byType(ProductListItemTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Chip Ngừng KD vẫn được chọn
      final chip = tester.widget<VChip>(inactiveChipFinder);
      expect(chip.selected, isTrue);
      final filterChips = tester.widget<ProductCatalogFilterChips>(find.byType(ProductCatalogFilterChips));
      expect(filterChips.selectedFilter, ProductListFilter.inactive);

      // 2. criteria.last.businessStatuses == {ProductBusinessStatus.inactive}
      expect(repo.recordedCriteria.isNotEmpty, isTrue);
      final lastCriteria = repo.recordedCriteria.last;
      expect(lastCriteria?.businessStatuses, {ProductBusinessStatus.inactive});

      // 3. Chỉ sản phẩm ngừng KD xuất hiện trong danh sách
      final tiles = tester.widgetList<ProductListItemTile>(find.byType(ProductListItemTile));
      expect(tiles.isNotEmpty, isTrue);
      for (final tile in tiles) {
        expect(tile.item.businessStatus, ProductBusinessStatus.inactive);
      }

      expect(find.byKey(_pccKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_deactivate_refreshes_list: ngừng KD kích hoạt onMutated tải lại danh sách', (tester) async {
      final repo = FakeProductRepository(
        backend: FakeCatalogBackend(scenario: FakeCatalogScenario.pccReadyToSell),
      );
      await pumpCatalogApp(
        tester,
        productRepository: repo,
        size: _wide,
        location: '/products/items/product-1',
      );
      final beforeCalls = catalogSearchCalls(repo);

      await _openDangerSection(tester);
      final deactivateButton = find.descendant(
        of: find.byType(ProductControlCenterPage),
        matching: find.text('Ngừng kinh doanh'),
      );
      await tester.ensureVisible(deactivateButton);
      await tester.tap(deactivateButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Xác nhận ngừng kinh doanh trên sheet
      await tester.tap(find.text('Ngừng kinh doanh').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Đã cập nhật trạng thái kinh doanh của sản phẩm.'), findsOneWidget);
      expect(catalogSearchCalls(repo), greaterThan(beforeCalls));
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_delete_clears_detail: xoá sản phẩm đưa ô phải về rỗng và URL về /products/items', (tester) async {
      final repo = FakeProductRepository(
        backend: FakeCatalogBackend(scenario: FakeCatalogScenario.pccReadyToSell),
      );
      await pumpCatalogApp(
        tester,
        productRepository: repo,
        size: _wide,
        location: '/products/items/product-1',
      );
      final beforeCalls = catalogSearchCalls(repo);

      await _openDangerSection(tester);
      final deleteButton = find.descendant(
        of: find.byType(ProductControlCenterPage),
        matching: find.text('Xoá sản phẩm'),
      );
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bấm nút Xoá sản phẩm trong hộp thoại xác nhận
      await tester.tap(find.text('Xoá sản phẩm').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(catalogCurrentPath, '/products/items');
      expect(find.text(_emptyDetail), findsOneWidget);
      expect(find.byType(ProductControlCenterPage), findsNothing);
      expect(catalogSearchCalls(repo), greaterThan(beforeCalls));
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_subscreen_full_page: mở màn con toàn màn hình, back về 2 cột', (tester) async {
      await pumpCatalogApp(tester, size: _wide, location: '/products/items/product-1');

      await tester.scrollUntilVisible(
        find.text('Ghi chú'),
        200,
        scrollable: find.descendant(
          of: find.byType(ProductControlCenterPage),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.text('Ghi chú'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Màn ghi chú chiếm toàn màn: StoreShell không chứa ProductNoteEditPage (root route)
      expect(find.byType(ProductNoteEditPage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StoreShell),
          matching: find.byType(ProductNoteEditPage),
        ),
        findsNothing,
      );

      // Quay lại
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Về lại 2 cột
      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(find.byKey(_pccKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('split_w6_no_extra: mở màn con trực tiếp không extra trên split về PCC 2 cột', (tester) async {
      await pumpCatalogApp(tester, size: _wide, location: '/products/items/product-1');

      appRouter.go('/products/items/product-1/note');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(catalogCurrentPath, '/products/items/product-1');
      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(find.byKey(_pccKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w9_sheets_are_dialogs_1280: mở sheet trên màn 1280 là VSheetDialog thay vì BottomSheet, đóng bằng Escape', (tester) async {
      await pumpCatalogApp(tester, size: _wide, location: '/products/items/product-1');

      // 1. Sheet lọc danh sách
      await tester.tap(find.byKey(const Key('btn_filter_custom_fields')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Lọc sản phẩm'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsNothing);

      // 2. Sheet ngừng kinh doanh
      await _openDangerSection(tester);
      final deactivateButton = find.descendant(
        of: find.byType(ProductControlCenterPage),
        matching: find.text('Ngừng kinh doanh'),
      );
      await tester.ensureVisible(deactivateButton);
      await tester.tap(deactivateButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Ngừng kinh doanh sản phẩm này?'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsNothing);

      // 3. Sheet chọn nguồn ảnh (ProductImageAddSheet)
      ProductImageAddSheet.show(tester.element(find.byType(ProductCatalogTabPage)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Thêm ảnh sản phẩm'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VSheetDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
