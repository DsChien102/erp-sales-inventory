import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_transform_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildRouter({
    required FakePartnerModule partnerModule,
    required List<String> permissions,
    String initialLocation = '/',
  }) {
    final session = IamSession()
      ..apply(
        PrincipalAccessDto(
          userId: 'user-1',
          tenantId: 'tenant-1',
          role: 'staff',
          permissions: permissions,
        ),
      );

    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IamSession>(session);

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
            partnerModule: partnerModule,
            executionContext: getIt<IExecutionContext>(),
          ),
        ),
        GoRoute(
          path: '/partner/:partnerId',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            final showTransformSuccessToast = state.uri.queryParameters['transformed'] == '1';
            return PartnerDetailPage(
              partnerId: partnerId,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
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
          partnerModule: FakePartnerModule(
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
      expect(find.text('02838225511'), findsOneWidget);

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
          partnerModule: FakePartnerModule(
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
            partnerModule: FakePartnerModule(
              scenario: FakePartnerScenario.transformPermissionDenied,
            ),
            executionContext: FakeExecutionContext(),
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
            partnerModule: FakePartnerModule(
              scenario: FakePartnerScenario.transformDupWarning,
            ),
            executionContext: FakeExecutionContext(),
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
          partnerModule: FakePartnerModule(
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
          partnerModule: FakePartnerModule(
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
      expect(find.text('Người liên hệ chính'), findsOneWidget);
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

      await tester.ensureVisible(find.text('Người liên hệ chính'));
      await tester.tap(find.text('Người liên hệ chính'));
      await tester.pumpAndSettle();
      expect(find.text('Danh xưng'), findsOneWidget);
      expect(find.text('Chị'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.textContaining('Trần Thị B'), findsWidgets);
      expect(find.text('SĐT phụ'), findsOneWidget);
      expect(find.text('0281111222'), findsOneWidget);
      expect(find.text('tranthib@abc.vn'), findsOneWidget);
      expect(find.text('Là liên hệ chính'), findsOneWidget);
      expect(find.text('Có'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u04_fr01_01: deleted partner shows not-found state',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerModule(
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
}
