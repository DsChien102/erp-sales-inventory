// Plan 5-W, Task 0 — test giữ hành vi (W1–W7, W9) trên code hiện tại.
//
// Dựng qua `appRouter` thật + `FakeCatalogBackend`, bề rộng 390 × 844 (hẹp).
// Viết và chạy xanh trên code TRƯỚC 5-W; sau khi sửa router / PCC / shell phải xanh y hệt
// (không đổi điều kiện kiểm, chỉ đổi cách dựng / đường dẫn).
import 'package:erp/core/router/app_router.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation/pages/edit_product_unit_price_band_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_catalog_tab_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_change_history_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_custom_field_group_edit_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_images_maintenance_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_manual_base_price_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_measurement_units_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_price_bands_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_profile_maintenance_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_page.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';

import '../catalog_e2e_harness.dart';
import '../support/catalog_router_harness.dart';
import '../support/fake_catalog_repositories.dart';
import '../support/fake_catalog_scenario.dart';

Future<void> _openDangerSection(WidgetTester tester) async {
  final dangerSection = find.byKey(const Key('btn_product_lifecycle_danger_toggle'));
  await tester.scrollUntilVisible(
    dangerSection,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(dangerSection);
  await tester.pumpAndSettle();
}

void main() {
  setUp(setUpCatalogRouterTest);
  tearDown(tearDownCatalogRouterTest);

  const pccKey = Key('wgt_e01_u02_fr01_01');

  group('5-W Task 0 — W1: mở danh sách gọi search đúng 1 lần', () {
    testWidgets('w1_open_list_searches_once', (tester) async {
      await pumpCatalogApp(tester);
      final repo = GetIt.instance<ProductRepository>() as FakeProductRepository;
      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(catalogSearchCalls(repo), 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W2: chọn dòng mở PCC, back về danh sách tải lại', () {
    testWidgets('w2_open_pcc_and_back_refreshes', (tester) async {
      await pumpCatalogApp(tester);
      final repo = GetIt.instance<ProductRepository>() as FakeProductRepository;
      expect(find.text('Amoxicillin 500mg'), findsWidgets);
      final searchBefore = catalogSearchCalls(repo);

      await tester.tap(find.text('Amoxicillin 500mg').first);
      await tester.pumpAndSettle();
      expect(find.byKey(pccKey), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsWidgets);

      // Bấm nút back
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(catalogSearchCalls(repo), searchBefore + 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W3: tạo sản phẩm mới mở PCC của sản phẩm mới', () {
    testWidgets('w3_create_opens_new_pcc', (tester) async {
      await pumpCatalogApp(tester);
      await tester.tap(find.byKey(const Key('btn_create_product')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductGuidedCreatePage), findsOneWidget);

      await createMinimalProduct(tester, name: 'Sản phẩm mới W3');
      expect(find.byKey(pccKey), findsOneWidget);
      expect(find.text('Sản phẩm mới W3'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W4: ngừng kinh doanh toast; sửa ghi chú tải lại PCC', () {
    testWidgets('w4_deactivate_toast', (tester) async {
      await pumpCatalogApp(tester);
      await tester.tap(find.text('Amoxicillin 500mg').first);
      await tester.pumpAndSettle();

      await _openDangerSection(tester);
      await tester.tap(find.text('Ngừng kinh doanh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngừng kinh doanh').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Đã cập nhật trạng thái kinh doanh của sản phẩm.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('w4_note_saved_reloads_pcc', (tester) async {
      await pumpCatalogApp(tester);
      await tester.tap(find.text('Amoxicillin 500mg').first);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Ghi chú'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ghi chú'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductNoteEditPage), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_product_note')), 'ghi chú mới');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_note_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(pccKey), findsOneWidget);
      expect(find.text('Đã điền ghi chú'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W5: xoá sản phẩm về danh sách, tải lại danh sách', () {
    testWidgets('w5_delete_back_to_list_refreshes', (tester) async {
      await pumpCatalogApp(tester);
      final repo = GetIt.instance<ProductRepository>() as FakeProductRepository;
      final searchBefore = catalogSearchCalls(repo);

      await tester.scrollUntilVisible(
        find.text('Thuốc thiếu đơn vị'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Thuốc thiếu đơn vị'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await _openDangerSection(tester);
      await tester.tap(find.text('Xoá sản phẩm').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Xoá sản phẩm').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sản phẩm đã được xóa thành công.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProductCatalogTabPage), findsOneWidget);
      expect(catalogSearchCalls(repo), greaterThan(searchBefore));
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W6: 11 màn con mở đúng từ PCC', () {
    Future<void> openPcc(
      WidgetTester tester, {
      String scenario = FakeCatalogScenario.guidedCreateOk,
      String productName = 'Amoxicillin 500mg',
    }) async {
      await pumpCatalogApp(tester, scenario: scenario);
      await tester.tap(find.text(productName).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(pccKey), findsOneWidget);
    }

    testWidgets('w6_checklist_opens', (tester) async {
      await openPcc(
        tester,
        scenario: FakeCatalogScenario.pccIncomplete,
        productName: 'Vitamin B Complex',
      );
      await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProductReadinessChecklistPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_profile_maintenance_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Hồ sơ sản phẩm'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductProfileMaintenancePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_images_maintenance_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Ảnh sản phẩm'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductImagesMaintenancePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_measurement_units_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Đơn vị đo lường'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductMeasurementUnitsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_stock_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Xem tồn kho'));
      await tester.pumpAndSettle();
      expect(find.byType(StockDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_note_opens', (tester) async {
      await openPcc(tester);
      await tester.scrollUntilVisible(
        find.text('Ghi chú'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ghi chú'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductNoteEditPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_manual_base_price_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Giá cơ sở'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductManualBasePricePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_price_bands_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Khung giá'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductPriceBandsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_price_bands_edit_opens', (tester) async {
      await openPcc(tester);
      await tester.tap(find.text('Khung giá'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductPriceBandsPage), findsOneWidget);

      await tester.tap(find.text('Sửa').first);
      await tester.pumpAndSettle();
      expect(find.byType(EditProductUnitPriceBandPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_custom_fields_edit_opens', (tester) async {
      await openPcc(tester, scenario: FakeCatalogScenario.pccCustomFieldCards);
      await tester.scrollUntilVisible(
        find.text('Thông tin thuốc'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Thông tin thuốc'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCustomFieldGroupEditPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('w6_change_history_opens', (tester) async {
      await openPcc(tester);
      await tester.scrollUntilVisible(
        find.text('Lịch sử thay đổi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lịch sử thay đổi'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductChangeHistoryPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W7: mở sản phẩm trùng từ màn tạo giữ nguyên form khi back', () {
    testWidgets('w7_open_duplicate_and_back_keeps_form', (tester) async {
      await pumpCatalogApp(tester, scenario: FakeCatalogScenario.guidedCreateDupSku);
      await tester.tap(find.byKey(const Key('btn_create_product')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductGuidedCreatePage), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_guided_name')), 'Thuốc trùng');
      await tester.enterText(find.byKey(const Key('input_guided_sku')), 'SKU-001');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_guided_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_open_duplicate_product')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_open_duplicate_product')));
      await tester.pumpAndSettle();

      expect(find.byKey(pccKey), findsOneWidget);

      // Quay lại màn tạo
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(ProductGuidedCreatePage), findsOneWidget);
      expect(find.text('Thuốc trùng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('5-W Task 0 — W9: các sheet là BottomSheet ở màn 390', () {
    testWidgets('w9_sheets_are_bottom_sheets_390', (tester) async {
      await pumpCatalogApp(tester);

      // 1. Sheet lọc danh sách
      await tester.tap(find.byKey(const Key('btn_filter_custom_fields')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VSheetDialog), findsNothing);
      // Đóng sheet lọc
      await tester.tap(find.byKey(const Key('btn_filter_reset')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Sheet ngừng kinh doanh
      await tester.tap(find.text('Amoxicillin 500mg').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _openDangerSection(tester);
      await tester.tap(find.text('Ngừng kinh doanh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VSheetDialog), findsNothing);
      // Đóng sheet
      await tester.tap(find.text('Huỷ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Sheet nguồn ảnh
      await tester.scrollUntilVisible(
        find.text('Ảnh sản phẩm'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ảnh sản phẩm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProductImagesMaintenancePage), findsOneWidget);

      final addImageBtn = find.descendant(
        of: find.byType(ProductImagesMaintenancePage),
        matching: find.text('Thêm'),
      );
      await tester.tap(addImageBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VSheetDialog), findsNothing);

      // Đóng sheet
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    group('Task 4 - New routes & redirects', () {
      const subScreens = [
        'checklist',
        'profile-maintenance',
        'images-maintenance',
        'measurement-units',
        'note',
        'manual-base-price',
        'price-bands',
        'price-bands/edit',
        'custom-fields/edit',
        'change-history',
      ];

      testWidgets('route_new_is_create_not_pcc', (tester) async {
        await pumpCatalogApp(tester);
        appRouter.go('/products/items/new');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ProductGuidedCreatePage), findsOneWidget);
        expect(find.byType(ProductControlCenterPage), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('w6_no_extra_redirects_from_tab', (tester) async {
        await pumpCatalogApp(tester, location: '/products/items/product-1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ProductControlCenterPage), findsOneWidget);

        for (final sub in subScreens) {
          appRouter.go('/products/items/product-1/$sub');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(catalogCurrentPath, '/products/items/product-1');
          expect(find.byType(ProductControlCenterPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('w6_no_extra_redirects_from_list', (tester) async {
        await pumpCatalogApp(tester, location: '/products/items');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        for (final sub in subScreens) {
          appRouter.go('/products/items/product-1/$sub');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(catalogCurrentPath, '/products/items/product-1');
          expect(find.byType(ProductControlCenterPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('deep_link_pcc_opens_in_tab', (tester) async {
        await pumpCatalogApp(tester, location: '/products/items/product-1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ProductControlCenterPage), findsOneWidget);
        expect(find.text('Amoxicillin 500mg'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('w10_pcc_keeps_bottom_tabs: mở PCC trong tab vẫn giữ bottom navigation', (tester) async {
        await pumpCatalogApp(tester, location: '/products/items/product-1');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ProductControlCenterPage), findsOneWidget);
        expect(find.byType(ErpBottomNavigation), findsOneWidget);

        // Bấm nút back trên PCC quay lại danh sách
        final backButton = find.descendant(
          of: find.byType(ProductControlCenterPage),
          matching: find.byWidgetPredicate(
            (w) => w is IconButton && w.icon is VIcon && (w.icon as VIcon).icon == VIcons.arrowBack,
          ),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ProductCatalogTabPage), findsOneWidget);
        expect(find.byType(ErpBottomNavigation), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
