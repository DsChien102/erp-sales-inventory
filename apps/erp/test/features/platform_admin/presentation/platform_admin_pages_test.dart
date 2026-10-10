import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/platform_admin/presentation/pages/platform_change_owner_page.dart';
import 'package:erp/features/platform_admin/presentation/pages/platform_organization_detail_page.dart';
import 'package:erp/features/platform_admin/presentation/pages/platform_organizations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/fake_platform_tenant_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakePlatformTenantRepository repository, {
  required String start,
  List<String>? visited,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
      GoRoute(
        path: '/more/platform/organizations',
        builder: (_, _) => PlatformOrganizationsPage(repository: repository),
      ),
      GoRoute(
        path: '/more/platform/organizations/:id',
        builder: (_, state) {
          visited?.add(state.uri.path);
          return PlatformOrganizationDetailPage(
            tenantId: state.pathParameters['id']!,
            repository: repository,
          );
        },
      ),
      GoRoute(
        path: '/more/platform/organizations/:id/owner',
        builder: (_, state) => PlatformChangeOwnerPage(
          tenantId: state.pathParameters['id']!,
          repository: repository,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  group('C1 — danh sách', () {
    testWidgets('shows title, search, four chips and tenant cards', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations');

      expect(find.text('Tổ chức'), findsOneWidget);
      expect(find.text('Quản trị nền tảng'), findsOneWidget);
      expect(find.text('Tìm tên hoặc mã tổ chức'), findsOneWidget);
      for (final label in ['Tất cả', 'Đang hoạt động', 'Tạm ngừng', 'Đã đóng']) {
        expect(find.widgetWithText(VChip, label), findsOneWidget, reason: label);
      }
      expect(find.text('Tổ chức t-1'), findsOneWidget);
      expect(find.text('Tổ chức t-2'), findsOneWidget);
      expect(find.textContaining('Chủ sở hữu: Lê Thị Lan'), findsWidgets);
      expect(find.textContaining('3 thành viên'), findsWidgets);
      expect(find.textContaining('Mức hoàn thiện'), findsNothing);
      expect(find.textContaining('Khởi tạo tổ chức'), findsNothing);
    });

    testWidgets('a status chip narrows the list', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations');

      await tester.tap(find.widgetWithText(VChip, 'Tạm ngừng'));
      await tester.pumpAndSettle();

      expect(find.text('Tổ chức t-1'), findsNothing);
      expect(find.text('Tổ chức t-2'), findsOneWidget);
      expect(repository.searches.last['status'], 'suspended');
    });

    testWidgets('empty shows "Chưa có tổ chức" without a create action', (tester) async {
      final repository = FakePlatformTenantRepository(tenants: []);
      await _pump(tester, repository, start: '/more/platform/organizations');

      expect(find.text('Chưa có tổ chức'), findsOneWidget);
      expect(find.textContaining('Khởi tạo'), findsNothing);
    });

    testWidgets('error offers a retry', (tester) async {
      final repository = FakePlatformTenantRepository()..searchError = serverError('SYSTEM_ERROR');
      await _pump(tester, repository, start: '/more/platform/organizations');

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);

      repository.searchError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Tổ chức t-1'), findsOneWidget);
    });

    testWidgets('no permission is not a retry loop', (tester) async {
      final repository = FakePlatformTenantRepository()
        ..searchError = serverError('PLATFORM_PERMISSION_DENIED');
      await _pump(tester, repository, start: '/more/platform/organizations');

      expect(find.text('Không có quyền xem tổ chức'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('tapping a card opens the detail', (tester) async {
      final visited = <String>[];
      final repository = FakePlatformTenantRepository();
      await _pump(
        tester,
        repository,
        start: '/more/platform/organizations',
        visited: visited,
      );

      await tester.tap(find.text('Tổ chức t-1'));
      await tester.pumpAndSettle();

      expect(visited, ['/more/platform/organizations/t-1']);
      expect(find.text('Chi tiết tổ chức'), findsOneWidget);
    });
  });

  group('C2 — chi tiết', () {
    testWidgets('active: owner, members, platform info, no onboarding fields', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');

      expect(find.text('Mậu Hiền'), findsOneWidget);
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('Thành viên tổ chức'), findsOneWidget);
      expect(find.text('3 thành viên'), findsOneWidget);
      expect(find.text('Thông tin nền tảng'), findsOneWidget);
      expect(find.text('Ngày đăng ký'), findsOneWidget);
      expect(find.text('Hoạt động gần nhất'), findsOneWidget);
      expect(find.text('Phiên bản dữ liệu'), findsNothing);
      expect(find.text('Kích hoạt lúc'), findsNothing);
      expect(find.textContaining('Hồ sơ cơ bản chưa hoàn thiện'), findsNothing);
      expect(find.text('Thao tác'), findsOneWidget);
    });

    testWidgets('suspended shows the block alert and reason', (tester) async {
      final repository = FakePlatformTenantRepository(
        tenantDetail: detail('t-1', status: TenantStatus.suspended),
      );
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');

      expect(find.text('Quyền vận hành đã bị chặn'), findsOneWidget);
      expect(find.text('Tạm ngừng lúc'), findsOneWidget);
      expect(find.text('Vi phạm'), findsOneWidget);
      expect(find.text('Admin A'), findsOneWidget);
    });

    testWidgets('closed hides Thao tác and shows the permanent alert', (tester) async {
      final repository = FakePlatformTenantRepository(
        tenantDetail: detail('t-1', status: TenantStatus.closed),
      );
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');

      expect(find.text('Tổ chức đã đóng vĩnh viễn'), findsOneWidget);
      expect(find.text('Thao tác'), findsNothing);
    });

    testWidgets('C3 for active: suspend, close and change owner — no restore', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();

      expect(find.text('Thao tác tổ chức'), findsOneWidget);
      expect(find.text('Tạm ngừng tổ chức'), findsOneWidget);
      expect(find.text('Đóng tổ chức'), findsOneWidget);
      expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
      expect(find.text('Khôi phục tổ chức'), findsNothing);
      expect(find.textContaining('Gửi lại email'), findsNothing);
    });

    testWidgets('C3 for suspended: restore, close and change owner — no suspend', (tester) async {
      final repository = FakePlatformTenantRepository(
        tenantDetail: detail('t-1', status: TenantStatus.suspended),
      );
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();

      expect(find.text('Khôi phục tổ chức'), findsOneWidget);
      expect(find.text('Đóng tổ chức'), findsOneWidget);
      expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
      expect(find.text('Tạm ngừng tổ chức'), findsNothing);
    });

    testWidgets('C4 suspend requires a reason, then calls the RPC and toasts', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('Tạm ngừng tổ chức?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('platform_confirm_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập lý do.'), findsOneWidget);
      expect(repository.calls, isEmpty);

      repository.tenantDetail = detail('t-1', status: TenantStatus.suspended, version: 5);
      await tester.enterText(find.byType(TextField), 'Vi phạm điều khoản');
      await tester.tap(find.byKey(const Key('platform_confirm_submit')));
      await tester.pumpAndSettle();

      expect(repository.calls.single.name, 'suspend');
      expect(repository.calls.single.args['reason'], 'Vi phạm điều khoản');
      expect(find.text('Đã tạm ngừng tổ chức thành công.'), findsOneWidget);
      expect(find.text('Đã tạm ngừng'), findsOneWidget);
      expect(find.text('Quyền vận hành đã bị chặn'), findsOneWidget);
    });

    testWidgets('C4 restore has no reason field', (tester) async {
      final repository = FakePlatformTenantRepository(
        tenantDetail: detail('t-1', status: TenantStatus.suspended),
      );
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khôi phục tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('Khôi phục tổ chức?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      repository.tenantDetail = detail('t-1');
      await tester.tap(find.byKey(const Key('platform_confirm_submit')));
      await tester.pumpAndSettle();

      expect(repository.calls.single.name, 'restore');
      expect(find.text('Đã khôi phục tổ chức thành công.'), findsOneWidget);
    });

    testWidgets('C4 close uses the close reason and the permanent message', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng tổ chức'));
      await tester.pumpAndSettle();

      expect(find.text('Đóng tổ chức?'), findsOneWidget);
      expect(find.textContaining('không thể khôi phục'), findsWidgets);

      repository.tenantDetail = detail('t-1', status: TenantStatus.closed);
      await tester.enterText(find.byType(TextField), 'Ngừng kinh doanh');
      await tester.tap(find.byKey(const Key('platform_confirm_submit')));
      await tester.pumpAndSettle();

      expect(repository.calls.single.name, 'close');
      expect(find.text('Đã đóng tổ chức.'), findsOneWidget);
      expect(find.text('Thao tác'), findsNothing);
    });

    testWidgets('a stale version shows the reload message', (tester) async {
      final repository = FakePlatformTenantRepository();
      await _pump(tester, repository, start: '/more/platform/organizations/t-1');
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng tổ chức'));
      await tester.pumpAndSettle();
      repository.mutationError = serverError('STATE_CHANGED');
      await tester.enterText(find.byType(TextField), 'Lý do');
      await tester.tap(find.byKey(const Key('platform_confirm_submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.'),
        findsOneWidget,
      );
    });
  });

  group('C5 / C6 — chuyển chủ sở hữu', () {
    Future<void> openOwnerPage(WidgetTester tester, FakePlatformTenantRepository repo) async {
      await _pump(tester, repo, start: '/more/platform/organizations/t-1');
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thay đổi chủ sở hữu'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists active members and greys out the current owner', (tester) async {
      final repository = FakePlatformTenantRepository();
      await openOwnerPage(tester, repository);

      expect(find.text('Chọn thành viên đang hoạt động'), findsOneWidget);
      expect(find.text('Vai trò hiện hành của thành viên sẽ được giữ nguyên.'), findsOneWidget);
      expect(find.text('Chủ sở hữu hiện tại · không chọn được'), findsOneWidget);
      expect(find.text('Trần Thị Hoa'), findsOneWidget);
      expect(find.text('Nguyễn Văn Minh'), findsOneWidget);

      final next = tester.widget<VButton>(find.byKey(const Key('platform_change_owner_continue')));
      expect(next.onPressed, isNull);
    });

    testWidgets('tapping the current owner does not enable continue', (tester) async {
      final repository = FakePlatformTenantRepository();
      await openOwnerPage(tester, repository);

      await tester.tap(find.byKey(const Key('platform_owner_candidate_owner-1')));
      await tester.pump();

      final next = tester.widget<VButton>(find.byKey(const Key('platform_change_owner_continue')));
      expect(next.onPressed, isNull);
    });

    testWidgets('search narrows the list; empty search shows the message', (tester) async {
      final repository = FakePlatformTenantRepository();
      await openOwnerPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'minh');
      await tester.pump();
      expect(find.text('Trần Thị Hoa'), findsNothing);
      expect(find.text('Nguyễn Văn Minh'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Không tìm thấy thành viên phù hợp'), findsOneWidget);
    });

    testWidgets('no other active member shows the empty message', (tester) async {
      final repository = FakePlatformTenantRepository(
        tenantMembers: [member('owner-1', name: 'Lê Thị Lan', isOwner: true)],
      );
      await openOwnerPage(tester, repository);

      expect(find.text('Chưa có thành viên đang hoạt động'), findsOneWidget);
    });

    testWidgets('confirm sheet names both owners and transfers', (tester) async {
      final repository = FakePlatformTenantRepository();
      await openOwnerPage(tester, repository);

      await tester.tap(find.byKey(const Key('platform_owner_candidate_user-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('platform_change_owner_continue')));
      await tester.pumpAndSettle();

      expect(find.text('Chuyển quyền sở hữu cho Trần Thị Hoa?'), findsOneWidget);
      expect(find.text('Chủ sở hữu hiện tại'), findsOneWidget);
      expect(find.text('Chủ sở hữu mới'), findsOneWidget);
      expect(
        find.textContaining(
          'Lê Thị Lan vẫn giữ vai trò Chủ cửa hàng. '
          'Trần Thị Hoa tiếp tục giữ vai trò Nhân viên bán hàng.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Bạn vẫn giữ'), findsNothing);

      await tester.tap(find.byKey(const Key('platform_change_owner_confirm')));
      await tester.pumpAndSettle();

      expect(repository.calls.single.name, 'transfer');
      expect(repository.calls.single.args['newOwnerUserId'], 'user-2');
      expect(find.text('Đã chuyển quyền sở hữu.'), findsOneWidget);
      expect(find.text('Chi tiết tổ chức'), findsOneWidget);
    });

    testWidgets('a rejected target keeps the page and shows the message', (tester) async {
      final repository = FakePlatformTenantRepository();
      await openOwnerPage(tester, repository);
      await tester.tap(find.byKey(const Key('platform_owner_candidate_user-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('platform_change_owner_continue')));
      await tester.pumpAndSettle();
      repository.mutationError = serverError('OWNER_TARGET_INVALID');
      await tester.tap(find.byKey(const Key('platform_change_owner_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Không thể chọn thành viên này.'), findsOneWidget);
      expect(find.text('Thay đổi chủ sở hữu'), findsOneWidget);
    });
  });
}
