import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_transform_page.dart';
import 'package:erp/features/partner/logic/partner_permissions.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/core/session/session_controller.dart';
import '../../../../core/session/fake_session_repository.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import '../../support/fake_partner_repository.dart';
import '../../support/scripted_partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildRouter({
    required PartnerRepository partnerModule,
    required List<String> permissions,
    String initialLocation = '/',
  }) {
    final session = SessionStore()
      ..apply(
        SessionPrincipal(
          userId: 'user-1',
          tenantId: 'tenant-1',
          role: 'staff',
          isOwner: false,
          permissions: permissions,
        ),
      );

    getIt
      ..registerSingleton<PartnerRepository>(partnerModule)
      ..registerSingleton<SessionController>(
        SessionController(repository: FakeSessionRepository(), store: session),
      );

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PartnerListPage(),
        ),
        GoRoute(
          path: '/partner/:partnerId/transform',
          builder: (context, state) => PartnerTransformPage(
            partner: state.extra! as PartnerDetailDto,
            repository: partnerModule,
          ),
        ),
        GoRoute(
          path: '/partner/:partnerId',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            final showTransformSuccessToast = state.uri.queryParameters['transformed'] == '1';
            return PartnerDetailPage(
              partnerId: partnerId,
              repository: partnerModule,
              showTransformSuccessToast: showTransformSuccessToast,
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'wgt_e01_u06_fr01_01: eligible person opens transform step one',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonActive,
          ),
          permissions: const [
            PartnerPermissions.detailView,
            PartnerPermissions.transform,
          ],
          initialLocation: '/partner/p-person-1',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển thành tổ chức'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u06_fr01_01')), findsOneWidget);
      expect(find.text('Thông tin tổ chức (mới)'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);

      await tester.tap(find.byKey(const Key('transform_organization_type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transform_organization_name')),
        'Công ty TNHH An Phát',
      );
      await tester.enterText(
        find.byKey(const Key('transform_phone')),
        '028 3822 5511',
      );
      await tester.ensureVisible(
        find.byKey(const Key('transform_continue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();

      expect(find.text('Xem trước chuyển đổi'), findsOneWidget);
      expect(find.text('Trước khi chuyển'), findsOneWidget);
      expect(find.text('Sau khi chuyển'), findsOneWidget);
      expect(find.text('Công ty TNHH An Phát'), findsOneWidget);
      expect(find.text('028 3822 5511'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('transform_preview_continue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_preview_continue')));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận chuyển thành tổ chức?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('transform_confirmation_confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
      expect(find.byKey(const Key('toast_partner_transform_success')), findsOneWidget);
      expect(find.text('Đã chuyển đổi thành công.'), findsOneWidget);
    },
  );

  testWidgets(
    'wgt_e01_u06_fr01_02: transform action is hidden when unavailable',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.searchEmpty,
          ),
          permissions: const [PartnerPermissions.detailView],
          initialLocation: '/partner/p-person-2',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();

      expect(find.text('Chuyển thành tổ chức'), findsNothing);
    },
  );

  testWidgets(
    'primary contact cannot transform and can open its organization',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonPrimaryContact,
          ),
          permissions: const [
            PartnerPermissions.detailView,
            PartnerPermissions.transform,
          ],
          initialLocation: '/partner/p-contact-primary',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển thành tổ chức'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('transform_primary_contact_blocked_sheet')),
        findsOneWidget,
      );
      expect(find.text('Không thể chuyển thành tổ chức'), findsOneWidget);
      expect(find.textContaining('Công ty Minh Phát'), findsOneWidget);
      expect(find.byKey(const Key('wgt_e01_u06_fr01_01')), findsNothing);

      await tester.tap(
        find.byKey(const Key('transform_blocked_view_organization')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('transform_primary_contact_blocked_sheet')),
        findsNothing,
      );
      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
    },
  );

  testWidgets(
    'primary contact cannot be deleted and can open its organization',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonPrimaryContact,
          ),
          permissions: const [
            PartnerPermissions.detailView,
            PartnerPermissions.delete,
          ],
          initialLocation: '/partner/p-contact-primary',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delete_primary_contact_blocked_sheet')),
        findsOneWidget,
      );
      expect(find.text('Không thể xóa hồ sơ'), findsOneWidget);
      expect(find.textContaining('Công ty Minh Phát'), findsOneWidget);
      expect(find.textContaining('Hãy đổi hoặc gỡ'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('delete_blocked_view_organization')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delete_primary_contact_blocked_sheet')),
        findsNothing,
      );
      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u06_fr01_01: transform NO_PERMISSION shows blocked state',
    (tester) async {
      final partner = PartnerDetailDto(
        partnerId: 'p-person-1',
        partnerType: PartnerType.person,
        status: PartnerStatus.active,
        displayName: 'Nguyễn Văn A',
        roles: const [PartnerRoleType.customer],
        availableActions: const [PartnerAvailableAction.transform],
        expectedVersion: 1,
        personProfile: const PersonProfileDto(
          fullName: 'Nguyễn Văn A',
          phone: '0901234567',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PartnerTransformPage(
            partner: partner,
            repository: FakePartnerRepository(
              scenario: FakePartnerScenario.transformPermissionDenied,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transform_organization_type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transform_organization_name')),
        'Công ty TNHH An Phát',
      );
      await tester.enterText(
        find.byKey(const Key('transform_phone')),
        '028 3822 5511',
      );
      await tester.ensureVisible(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('transform_preview_continue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_preview_continue')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('transform_confirmation_confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transform_blocked_no_permission')), findsOneWidget);
      expect(find.text('Không có quyền chuyển đổi'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u06_fr01_01: transform DUPLICATE returns to step one with field error',
    (tester) async {
      final partner = PartnerDetailDto(
        partnerId: 'p-person-1',
        partnerType: PartnerType.person,
        status: PartnerStatus.active,
        displayName: 'Nguyễn Văn A',
        roles: const [PartnerRoleType.customer],
        availableActions: const [PartnerAvailableAction.transform],
        expectedVersion: 1,
        personProfile: const PersonProfileDto(
          fullName: 'Nguyễn Văn A',
          phone: '0901234567',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PartnerTransformPage(
            partner: partner,
            repository: FakePartnerRepository(
              scenario: FakePartnerScenario.transformDupWarning,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transform_organization_type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transform_organization_name')),
        'Công ty TNHH An Phát',
      );
      await tester.enterText(
        find.byKey(const Key('transform_phone')),
        '028 3822 5511',
      );
      await tester.ensureVisible(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_continue')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('transform_preview_continue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transform_preview_continue')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('transform_confirmation_confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chuyển thành tổ chức'), findsOneWidget);
      expect(find.text('Thông tin tổ chức (mới)'), findsOneWidget);
      expect(find.text('Xem trước chuyển đổi'), findsNothing);
      expect(find.byKey(const Key('transform_blocking_banner')), findsNothing);
      expect(
        find.text(PartnerTransformCubit.duplicatePhoneMessage),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'e2e_e01_u04_fr01_01: list opens person detail with type role status',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.defaultMixed,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
            PartnerPermissions.create,
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Nguyễn Văn A'), findsWidgets);

      await tester.tap(find.textContaining('Nguyễn Văn A').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsWidgets);
      expect(find.textContaining('Cá nhân'), findsWidgets);
      expect(find.textContaining('Khách hàng'), findsWidgets);
      expect(find.text('Đang hoạt động'), findsOneWidget);

      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);

      await tester.tap(find.text('Thông tin cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Danh xưng'), findsOneWidget);
      expect(find.text('Ông'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsWidgets);
      expect(find.text('Tên thường gọi'), findsOneWidget);
      expect(find.text('SĐT chính'), findsOneWidget);
      expect(find.text('0901234567'), findsWidgets);
      expect(find.text('SĐT phụ'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('nguyenvana@example.com'), findsOneWidget);

      await tester.ensureVisible(find.text('Hóa đơn / thuế'));
      await tester.tap(find.text('Hóa đơn / thuế'));
      await tester.pumpAndSettle();
      expect(find.text('MST'), findsOneWidget);
      expect(find.text('0101234567'), findsWidgets);
      expect(find.text('Tên xuất hóa đơn'), findsOneWidget);
      expect(find.text('Email nhận hóa đơn'), findsOneWidget);
      expect(find.text('Địa chỉ xuất hóa đơn'), findsOneWidget);
      expect(find.text('12 Nguyễn Huệ, Quận 1, TP.HCM'), findsOneWidget);

      await tester.ensureVisible(find.text('Ghi chú'));
      await tester.tap(find.text('Ghi chú'));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsWidgets);

      expect(find.text('Chỉnh sửa'), findsOneWidget);
      expect(find.textContaining('Thao tác'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u04_fr01_01: organization detail shows contacts card',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailOrganizationWithContacts,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
          ],
          initialLocation: '/partner/p-org-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
      expect(find.text('Công ty ABC'), findsWidgets);
      expect(find.textContaining('Tổ chức'), findsWidgets);
      expect(find.textContaining('KH & NCC'), findsWidgets);
      expect(find.text('Thông tin tổ chức'), findsOneWidget);
      expect(find.text('Người liên hệ'), findsOneWidget);
      expect(find.text('Hóa đơn / thuế'), findsOneWidget);
      expect(find.text('Địa chỉ giao hàng'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);

      await tester.tap(find.text('Thông tin tổ chức'));
      await tester.pumpAndSettle();
      expect(find.text('Loại tổ chức'), findsOneWidget);
      expect(find.text('Công ty'), findsOneWidget);
      expect(find.text('Tên tổ chức'), findsOneWidget);
      expect(find.text('Tên viết tắt'), findsOneWidget);
      expect(find.text('Tên quốc tế'), findsOneWidget);
      expect(find.text('SĐT chính'), findsWidgets);
      expect(find.text('0901234567'), findsWidgets);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('contact@abc.vn'), findsOneWidget);

      await tester.ensureVisible(find.text('Người liên hệ'));
      await tester.tap(find.text('Người liên hệ'));
      await tester.pumpAndSettle();
      expect(find.text('Trần Thị B'), findsWidgets);
      expect(find.text('Chính'), findsOneWidget);
      expect(find.text('Kế toán'), findsOneWidget);
      expect(find.text('tranthib@abc.vn'), findsOneWidget);
      expect(find.text('Thêm người liên hệ'), findsOneWidget);
      expect(find.text('Xem tất cả (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u04_fr01_01: deleted partner shows not-found state',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailDeleted,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
          ],
          initialLocation: '/partner/p-deleted',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy hồ sơ'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsNothing);
    },
  );

  testWidgets(
    'G6 (KI-10): loaded profile has no "Lịch sử gần đây" card, keeps system card',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonActive,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
          ],
          initialLocation: '/partner/p-person-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn A'), findsWidgets);
      expect(find.text('Lịch sử gần đây'), findsNothing);
      expect(find.text('Tính năng đang phát triển'), findsNothing);
      expect(find.byType(PartnerDetailSystemCard), findsOneWidget);
    },
  );

  group('PT-07 banner thiếu thông tin theo loại hồ sơ (TH-03 9.3)', () {
    const permissions = [PartnerPermissions.view, PartnerPermissions.detailView];

    Future<void> open(WidgetTester tester, PartnerDetailDto dto) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: ScriptedPartnerRepository(onCall: (_, _) => dto),
          permissions: permissions,
          initialLocation: '/partner/${dto.partnerId}',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cá nhân thiếu MST và địa chỉ hóa đơn → "Thiếu MST và địa chỉ hóa đơn."', (
      tester,
    ) async {
      await open(
        tester,
        PartnerDetailDto(
          partnerId: 'p-1',
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Nguyễn Văn A',
          roles: const [PartnerRoleType.customer],
          availableActions: const [],
          expectedVersion: 1,
          personProfile: const PersonProfileDto(fullName: 'Nguyễn Văn A', phone: '0901234567'),
        ),
      );

      expect(find.text('Hồ sơ còn thiếu thông tin'), findsOneWidget);
      expect(find.textContaining('Thiếu MST và địa chỉ hóa đơn.'), findsOneWidget);
    });

    testWidgets('tổ chức thiếu MST, tên và địa chỉ hóa đơn → liệt kê đủ 3 mục', (tester) async {
      await open(
        tester,
        PartnerDetailDto(
          partnerId: 'p-2',
          partnerType: PartnerType.organization,
          status: PartnerStatus.active,
          displayName: 'Công ty ABC',
          roles: const [PartnerRoleType.customer],
          availableActions: const [],
          expectedVersion: 1,
          organizationProfile: const OrganizationProfileDto(
            organizationType: OrganizationType.company,
            organizationName: 'Công ty ABC',
            phone: '0901234567',
          ),
        ),
      );

      expect(find.text('Hồ sơ còn thiếu thông tin'), findsOneWidget);
      expect(
        find.textContaining('Thiếu MST, tên xuất hóa đơn và địa chỉ hóa đơn.'),
        findsOneWidget,
      );
    });

    testWidgets('hồ sơ đủ thông tin → không có banner', (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.detailPersonActive,
          ),
          permissions: permissions,
          initialLocation: '/partner/p-person-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ còn thiếu thông tin'), findsNothing);
    });

    testWidgets('chỉ là người liên hệ (không vai trò) → "Không phải hồ sơ đối tác"', (
      tester,
    ) async {
      await open(
        tester,
        PartnerDetailDto(
          partnerId: 'p-3',
          partnerType: PartnerType.person,
          status: PartnerStatus.active,
          displayName: 'Trần Thị B',
          roles: const [],
          availableActions: const [],
          expectedVersion: 1,
          personProfile: const PersonProfileDto(fullName: 'Trần Thị B', phone: '0907654321'),
        ),
      );

      expect(find.text('Không phải hồ sơ đối tác'), findsOneWidget);
      expect(find.text('Hồ sơ còn thiếu thông tin'), findsNothing);
    });
  });
}
