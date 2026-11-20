// Plan 4-W, bước 0 — test giữ hành vi (W3–W9).
//
// Dựng qua `appRouter` thật + `FakePartnerRepository`, bề rộng 390 × 844 (hẹp).
// Viết và chạy xanh trên code TRƯỚC 4-W; sau khi sửa phải xanh y hệt
// (không đổi điều kiện kiểm, chỉ được đổi cách dựng).
import 'package:erp/core/router/app_router.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation/pages/partner_change_history_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contact_form_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contact_select_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contacts_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_transform_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../support/fake_partner_repository.dart';
import '../support/partner_router_harness.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakePartnerRepository repo,
  String location = '/partner',
}) => pumpPartnerApp(tester, repo: repo, location: location);

String get _path => partnerCurrentPath;

int _searchCalls(FakePartnerRepository repo) => partnerSearchCalls(repo);

void main() {
  setUp(setUpPartnerRouterTest);
  tearDown(tearDownPartnerRouterTest);

  const detailKey = Key('wgt_e01_u04_fr01_01');

  group('4-W bước 0 — W3: chọn dòng → hồ sơ → xoá → về danh sách', () {
    testWidgets('W3: chọn dòng mở hồ sơ; xoá xong về danh sách, toast xoá, danh sách tải lại', (
      tester,
    ) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.defaultMixed);
      await _pumpApp(tester, repo: repo);

      expect(find.byType(PartnerListPage), findsOneWidget);
      final searchesBefore = _searchCalls(repo);
      expect(searchesBefore, greaterThanOrEqualTo(1));

      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();
      expect(find.byKey(detailKey), findsOneWidget);
      expect(_path, '/partner/p-person-1');

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('soft_delete_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Đã xóa hồ sơ KH & NCC.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(find.byKey(detailKey), findsNothing);
      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(_path, '/partner');
      expect(_searchCalls(repo), greaterThan(searchesBefore));
    });
  });

  group('4-W bước 0 — W4: tạo xong → thấy hồ sơ mới + toast tạo', () {
    testWidgets('W4: tạo cá nhân', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.createPersonOk);
      await _pumpApp(tester, repo: repo);

      await tester.tap(find.byKey(const Key('btn_create_partner')));
      await tester.pumpAndSettle();
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

      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.text('Đã tạo KH & NCC thành công'), findsOneWidget);
      expect(_path, '/partner/p-new-1');
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('4-W bước 0 — W5: ngừng hoạt động / sửa → toast', () {
    testWidgets('W5a: ngừng hoạt động → toast', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await _pumpApp(tester, repo: repo, location: '/partner/p-person-1');

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngừng hoạt động'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deactivate_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Đã ngừng hoạt động KH & NCC.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    testWidgets('W5b: sửa → toast cập nhật', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await _pumpApp(tester, repo: repo, location: '/partner/p-person-1');

      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3. Thông tin cá nhân'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('input_full_name')), 'Trần Thị Hoa');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_save_view')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.text('Đã cập nhật hồ sơ KH & NCC'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });
  });

  group('4-W bước 0 — W6: mở thẳng hồ sơ rồi xoá → về /partner', () {
    testWidgets('W6', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await _pumpApp(tester, repo: repo, location: '/partner/p-person-1');

      expect(find.byKey(detailKey), findsOneWidget);
      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('soft_delete_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Đã xóa hồ sơ KH & NCC.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.byType(PartnerDetailPage), findsNothing);
      expect(_path, '/partner');
    });
  });

  group('4-W bước 0 — W7: sheet chặn → Xem tổ chức', () {
    testWidgets('W7', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonPrimaryContact);
      await _pumpApp(tester, repo: repo, location: '/partner/p-person-1');

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển thành tổ chức'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem tổ chức'));
      await tester.pumpAndSettle();

      expect(_path, '/partner/p-org-primary');
      expect(find.byKey(detailKey), findsOneWidget);
    });
  });

  group('4-W bước 0 — W8: 8 route /partner/... mở đúng trang', () {
    Future<void> open(
      WidgetTester tester,
      String path, {
      Object? extra,
      FakePartnerScenario scenario = FakePartnerScenario.detailOrganizationWithContacts,
    }) async {
      final repo = FakePartnerRepository(scenario: scenario);
      await _pumpApp(tester, repo: repo);
      appRouter.go(path, extra: extra);
      await tester.pumpAndSettle();
    }

    testWidgets('/partner/new', (tester) async {
      await open(tester, '/partner/new', extra: PartnerType.person);
      expect(find.byType(PartnerCreatePage), findsOneWidget);
      expect(_path, '/partner/new');
    });

    testWidgets('/partner/:id/edit', (tester) async {
      await open(tester, '/partner/p-org-1/edit');
      expect(find.byType(PartnerCreatePage), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    });

    testWidgets('/partner/:id/transform có extra', (tester) async {
      final dto = await FakePartnerRepository(
        scenario: FakePartnerScenario.detailPersonActive,
      ).getDetail('p-person-1');
      await open(
        tester,
        '/partner/p-person-1/transform',
        extra: dto,
        scenario: FakePartnerScenario.detailPersonActive,
      );
      expect(find.byType(PartnerTransformPage), findsOneWidget);
    });

    for (final from in ['/partner', '/partner/p-person-1']) {
      testWidgets('/partner/:id/transform thiếu extra → về hồ sơ (từ $from)', (tester) async {
        await _pumpApp(
          tester,
          repo: FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive),
          location: from,
        );
        appRouter.go('/partner/p-person-1/transform');
        await tester.pumpAndSettle();
        expect(find.byType(PartnerTransformPage), findsNothing);
        expect(find.byType(PartnerDetailPage), findsOneWidget);
        expect(_path, '/partner/p-person-1');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('/partner/:id/history', (tester) async {
      await open(tester, '/partner/p-org-1/history', extra: 'Công ty ABC');
      expect(find.byType(PartnerChangeHistoryPage), findsOneWidget);
    });

    testWidgets('/partner/:id/contacts', (tester) async {
      await open(tester, '/partner/p-org-1/contacts');
      expect(find.byType(PartnerContactsPage), findsOneWidget);
    });

    testWidgets('/partner/:id/contacts/new', (tester) async {
      await open(tester, '/partner/p-org-1/contacts/new');
      expect(find.byType(PartnerContactFormPage), findsOneWidget);
    });

    testWidgets('/partner/:id/contacts/select', (tester) async {
      await open(tester, '/partner/p-org-1/contacts/select');
      expect(find.byType(PartnerContactSelectPage), findsOneWidget);
    });

    testWidgets('/partner/:id/contacts/:contactId/edit', (tester) async {
      await open(tester, '/partner/p-org-1/contacts/p-contact-1/edit');
      expect(find.byType(PartnerContactFormPage), findsOneWidget);
    });

    testWidgets('/partner/:id (chi tiết)', (tester) async {
      await open(tester, '/partner/p-org-1');
      expect(find.byType(PartnerDetailPage), findsOneWidget);
      expect(find.byKey(detailKey), findsOneWidget);
    });
  });

  group('4-W bước 0 — W9: sheet ở bề rộng hẹp là BottomSheet', () {
    testWidgets('W9: sheet lọc + sheet thao tác', (tester) async {
      final repo = FakePartnerRepository(scenario: FakePartnerScenario.detailPersonActive);
      await _pumpApp(tester, repo: repo);

      await tester.tap(find.byIcon(VIcons.tune.value));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VSheetDialog), findsNothing);
      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      appRouter.go('/partner/p-person-1');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(VSheetDialog), findsNothing);
    });
  });

  group('4-W R1-2 — thao tác người liên hệ làm mới danh sách', () {
    testWidgets('vào "Người liên hệ" rồi quay lại → search tăng 1', (tester) async {
      final repo = FakePartnerRepository(
        scenario: FakePartnerScenario.detailOrganizationWithContacts,
      );
      await _pumpApp(tester, repo: repo, location: '/partner/p-org-1');
      final before = _searchCalls(repo);

      await tester.tap(find.text('Người liên hệ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Xem tất cả ('));
      await tester.pumpAndSettle();
      // Font Ahem làm hàng "Thêm / Xem tất cả" tràn ngang ở 390 (nút nằm ngoài
      // màn): gọi onTap của InkWell thay vì tap theo toạ độ.
      tester
          .widget<InkWell>(
            find
                .ancestor(of: find.textContaining('Xem tất cả ('), matching: find.byType(InkWell))
                .first,
          )
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(PartnerContactsPage), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.byType(PartnerDetailPage), findsOneWidget);
      expect(_searchCalls(repo), before + 1);
    });

    testWidgets('thêm người có sẵn từ hồ sơ → search tăng 1', (tester) async {
      final repo = OrganizationDetailMixedSearchRepository();
      await _pumpApp(tester, repo: repo, location: '/partner/p-org-1');

      await tester.tap(find.text('Người liên hệ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm người liên hệ'));
      await tester.pumpAndSettle();
      tester
          .widget<InkWell>(
            find
                .ancestor(of: find.text('Thêm người liên hệ'), matching: find.byType(InkWell))
                .first,
          )
          .onTap!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ cá nhân có sẵn'));
      await tester.pumpAndSettle();
      expect(find.byType(PartnerContactSelectPage), findsOneWidget);
      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();
      final before = _searchCalls(repo);

      await tester.tap(find.byKey(const Key('btn_contact_select_submit')));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('addContact'));
      expect(_searchCalls(repo), before + 1);
    });
  });
}
