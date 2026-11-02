// Plan 4-W, bước 6 — bố cục web 2 cột (1280 × 800), W1/W2/W10 và hộp thoại.
import 'package:erp/core/router/app_router.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/partner/logic/partner_permissions.dart';
import 'package:erp/features/partner/presentation/pages/partner_contact_select_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contacts_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_transform_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:erp/features/partner/presentation/widgets/partner_list_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/fake_partner_repository.dart';
import '../support/partner_router_harness.dart';

// Cao hơn 800 một chút: font Ahem làm thẻ danh sách cao hơn font thật nên 800
// chỉ vừa một thẻ; ListView lười không dựng thẻ thứ hai.
const _wide = Size(1280, 1100);
const _detailKey = Key('wgt_e01_u04_fr01_01');
const _noPermissionKey = Key('wgt_e01_u02_fr01_02');
const _emptyDetail = 'Chọn một KH & NCC để xem chi tiết.';

PartnerListItemTile _tile(WidgetTester tester, String partnerId) => tester
    .widgetList<PartnerListItemTile>(find.byType(PartnerListItemTile))
    .firstWhere((t) => t.item.partnerId == partnerId);

void main() {
  setUp(setUpPartnerRouterTest);
  tearDown(tearDownPartnerRouterTest);

  group('4-W bước 6 — web 2 cột (1280 × 800)', () {
    testWidgets('/partner: danh sách bên trái, ô phải trống với chuỗi Q4', (tester) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo, size: _wide);

      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.text(_emptyDetail), findsOneWidget);
      expect(find.byType(PartnerDetailPage), findsNothing);
      expect(find.byType(PartnerListItemTile), findsNWidgets(2));
      expect(partnerSearchCalls(repo), 1);
    });

    testWidgets('chọn dòng: URL đổi, hồ sơ hiện bên phải, dòng được đánh dấu chọn', (tester) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo, size: _wide);

      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();

      expect(partnerCurrentPath, '/partner/p-person-1');
      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.byKey(_detailKey), findsOneWidget);
      expect(find.text(_emptyDetail), findsNothing);
      expect(_tile(tester, 'p-person-1').isSelected, isTrue);
      expect(_tile(tester, 'p-org-1').isSelected, isFalse);
    });

    testWidgets('mở thẳng /partner/p-person-1: đủ 2 cột, dòng p-person-1 được chọn', (
      tester,
    ) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');

      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.byKey(_detailKey), findsOneWidget);
      expect(_tile(tester, 'p-person-1').isSelected, isTrue);
      // Chỉ một cubit danh sách: tải 1 lần dù có cả cột trái lẫn route hồ sơ.
      expect(partnerSearchCalls(repo), 1);
    });

    testWidgets('đổi từ hồ sơ A sang B hiện đúng hồ sơ B (ValueKey)', (tester) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');
      expect(
        tester.widget<PartnerDetailPage>(find.byType(PartnerDetailPage)).partnerId,
        'p-person-1',
      );
      expect(repo.calls.where((c) => c == 'getDetail').length, 1);

      await tester.tap(find.text('Công ty ABC'));
      await tester.pumpAndSettle();

      expect(partnerCurrentPath, '/partner/p-org-1');
      expect(tester.widget<PartnerDetailPage>(find.byType(PartnerDetailPage)).partnerId, 'p-org-1');
      // State của hồ sơ A không được giữ lại: hồ sơ B tải lại từ đầu.
      expect(repo.calls.where((c) => c == 'getDetail').length, 2);
      expect(_tile(tester, 'p-org-1').isSelected, isTrue);
      expect(_tile(tester, 'p-person-1').isSelected, isFalse);
    });

    testWidgets('hồ sơ không có nút Quay lại', (tester) async {
      await pumpPartnerApp(
        tester,
        repo: FakePartnerRepository(),
        size: _wide,
        location: '/partner/p-person-1',
      );
      for (final matching in [find.byTooltip('Quay lại'), find.byType(BackButton)]) {
        expect(
          find.descendant(of: find.byType(PartnerDetailPage), matching: matching),
          findsNothing,
        );
      }
    });

    testWidgets('W5: ngừng hoạt động → toast, danh sách tải lại (onMutated)', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');
      final before = partnerSearchCalls(repo);

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngừng hoạt động'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deactivate_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Đã ngừng hoạt động KH & NCC.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(partnerSearchCalls(repo), greaterThan(before));
    });

    testWidgets('W5: sửa → toast, danh sách tải lại (onMutated)', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');
      final before = partnerSearchCalls(repo);

      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3. Thông tin cá nhân'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('input_full_name')), 'Trần Thị Hoa');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_save_view')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(_detailKey), findsOneWidget);
      expect(find.text('Đã cập nhật hồ sơ KH & NCC'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(partnerSearchCalls(repo), greaterThan(before));
    });

    testWidgets('W6: xoá → toast, ô phải về trống, danh sách tải lại', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');
      final before = partnerSearchCalls(repo);

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('soft_delete_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Đã xóa hồ sơ KH & NCC.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(partnerCurrentPath, '/partner');
      expect(find.byType(PartnerDetailPage), findsNothing);
      expect(find.text(_emptyDetail), findsOneWidget);
      expect(partnerSearchCalls(repo), greaterThan(before));
    });

    testWidgets('W7: "Xem tổ chức" đổi cột phải sang hồ sơ tổ chức', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonPrimaryContact);
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-person-1');

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển thành tổ chức'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem tổ chức'));
      await tester.pumpAndSettle();

      expect(partnerCurrentPath, '/partner/p-org-primary');
      expect(
        tester.widget<PartnerDetailPage>(find.byType(PartnerDetailPage)).partnerId,
        'p-org-primary',
      );
      expect(find.byType(PartnerListPage), findsOneWidget);
    });

    testWidgets('W4: tạo xong mở hồ sơ mới ở cột phải kèm toast tạo', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.createPersonOk);
      await pumpPartnerApp(tester, repo: repo, size: _wide);

      await tester.tap(find.byKey(const Key('btn_create_partner')));
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsOneWidget);
      await tester.tap(find.byKey(const Key('partner_create_person')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role_customer')));
      await tester.tap(find.byKey(const Key('btn_next')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('input_full_name')), 'Nguyễn Văn Minh');
      await tester.enterText(find.byKey(const Key('input_phone')), '0901234567');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_save_view')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(partnerCurrentPath, '/partner/p-new-1');
      expect(find.byKey(_detailKey), findsOneWidget);
      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.text('Đã tạo KH & NCC thành công'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('4-W bước 6 — W9: sheet thành hộp thoại ≥ 1024', () {
    testWidgets('1280: sheet lọc là VSheetDialog, Esc đóng', (tester) async {
      await pumpPartnerApp(tester, repo: FakePartnerRepository(), size: _wide);

      await tester.tap(find.byIcon(VIcons.tune.value));
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('1280: sheet thao tác trong hồ sơ là VSheetDialog, Esc đóng', (tester) async {
      await pumpPartnerApp(
        tester,
        repo: FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive),
        size: _wide,
        location: '/partner/p-person-1',
      );

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsNothing);
    });
  });

  group('4-W — W1, W2, W10 (hẹp 390 × 844)', () {
    testWidgets('W1: mở /partner gọi search đúng 1 lần; sang hồ sơ rồi về vẫn 1 lần', (
      tester,
    ) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo);
      expect(partnerSearchCalls(repo), 1);

      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();
      appRouter.pop();
      await tester.pumpAndSettle();

      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(partnerSearchCalls(repo), 1);
    });

    testWidgets('W2: thiếu partner.view → thấy key; /partner/:id cũng bị chặn, không gọi RPC', (
      tester,
    ) async {
      final repo = FakePartnerRepository();
      await pumpPartnerApp(tester, repo: repo, permissions: const {});
      expect(find.byKey(_noPermissionKey), findsOneWidget);
      expect(find.text('Bạn không có quyền xem\nKH & NCC'), findsOneWidget);

      appRouter.go('/partner/p-person-1');
      await tester.pumpAndSettle();

      expect(find.byKey(_noPermissionKey), findsOneWidget);
      expect(find.text('Bạn không có quyền xem\nKH & NCC'), findsOneWidget);
      expect(find.byKey(_detailKey), findsNothing);
      expect(repo.calls, isNot(contains('getDetail')));
      expect(repo.calls, isNot(contains('search')));
    });

    testWidgets('W2: có partner.view → không thấy màn chặn', (tester) async {
      await pumpPartnerApp(
        tester,
        repo: FakePartnerRepository(),
        permissions: const {PartnerPermissions.view},
      );
      expect(find.text('Bạn không có quyền xem\nKH & NCC'), findsNothing);
      expect(find.byType(PartnerListPage), findsOneWidget);
    });

    testWidgets('W10: xem hồ sơ vẫn thấy thanh tab dưới; nút ← về danh sách', (tester) async {
      await pumpPartnerApp(tester, repo: FakePartnerRepository());
      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();

      expect(find.byKey(_detailKey), findsOneWidget);
      expect(find.byType(ErpBottomNavigation), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(_detailKey), findsNothing);
      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(partnerCurrentPath, '/partner');
    });
  });

  group('4-W R1 — 1280: transform thiếu extra, thao tác người liên hệ', () {
    testWidgets('R1-1: /partner/:id/transform thiếu extra → về hồ sơ, không lỗi GlobalKey', (
      tester,
    ) async {
      await pumpPartnerApp(
        tester,
        repo: FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive),
        size: _wide,
        location: '/partner',
      );
      appRouter.go('/partner/p-person-1/transform');
      await tester.pumpAndSettle();

      expect(find.byType(PartnerTransformPage), findsNothing);
      expect(find.byKey(_detailKey), findsOneWidget);
      expect(partnerCurrentPath, '/partner/p-person-1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('R1-2: vào "Người liên hệ" rồi quay lại → search tăng 1', (tester) async {
      final repo = FakePartnerRepository(
        scenario: FakePartnerScenario.detailOrganizationWithContacts,
      );
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-org-1');
      final before = partnerSearchCalls(repo);

      await tester.tap(find.text('Người liên hệ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Xem tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Xem tất cả'));
      await tester.pumpAndSettle();
      expect(find.byType(PartnerContactsPage), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(partnerSearchCalls(repo), before + 1);
    });

    testWidgets('R1-2: thêm người có sẵn từ hồ sơ → search tăng 1', (tester) async {
      final repo = OrganizationDetailMixedSearchRepository();
      await pumpPartnerApp(tester, repo: repo, size: _wide, location: '/partner/p-org-1');

      await tester.tap(find.text('Người liên hệ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm người liên hệ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm người liên hệ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ cá nhân có sẵn'));
      await tester.pumpAndSettle();
      expect(find.byType(PartnerContactSelectPage), findsOneWidget);
      await tester.tap(find.text('Nguyễn Văn A').last);
      await tester.pumpAndSettle();
      final before = partnerSearchCalls(repo);

      await tester.tap(find.byKey(const Key('btn_contact_select_submit')));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('addContact'));
      expect(partnerSearchCalls(repo), before + 1);
    });
  });
}
