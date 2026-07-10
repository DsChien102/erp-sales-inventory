import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
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
    String initialLocation = '/partner/p-1',
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
          path: '/partner/:partnerId/edit',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            return PartnerCreatePage.edit(
              partnerId: partnerId,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
              onUpdated: (_) {
                if (context.mounted) context.pop(true);
              },
              onOpenExisting: (_) {},
            );
          },
        ),
        GoRoute(
          path: '/partner/:partnerId',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            return PartnerDetailPage(
              partnerId: partnerId,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'e2e_e01_u03_fr01_01: detail opens edit, saves person update, returns',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerModule(
            scenario: FakePartnerScenario.detailPersonActive,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
            PartnerPermissions.update,
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
      expect(find.text('Chỉnh sửa'), findsOneWidget);

      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u03_fr01_01')), findsOneWidget);
      expect(find.text('Chỉnh sửa cá nhân'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(find.textContaining('Người liên hệ chính'), findsNothing);

      // Save stays disabled until the form is dirty.
      expect(
        tester.widget<VButton>(find.byKey(const Key('btn_save_view'))).onPressed,
        isNull,
      );

      await tester.tap(find.text('3. Thông tin cá nhân'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('input_full_name')),
        'Trần Thị Hoa',
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<VButton>(find.byKey(const Key('btn_save_view'))).onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('btn_save_view')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u04_fr01_01')), findsOneWidget);
      expect(find.byKey(const Key('wgt_e01_u03_fr01_01')), findsNothing);
      expect(find.text('Đã cập nhật hồ sơ KH & NCC'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u03_fr01_01: organization edit form opens from detail',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerModule(
            scenario: FakePartnerScenario.detailOrganizationWithContacts,
          ),
          permissions: const [
            PartnerPermissions.view,
            PartnerPermissions.detailView,
            PartnerPermissions.update,
          ],
          initialLocation: '/partner/p-org-1',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u03_fr01_01')), findsOneWidget);
      expect(find.text('Chỉnh sửa tổ chức'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(find.textContaining('Người liên hệ chính'), findsNothing);

      await tester.tap(find.text('3. Thông tin tổ chức'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('input_organization_name')), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u03_fr01_01: edit action disabled without update available',
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
      expect(find.text('Chỉnh sửa'), findsNothing);
    },
  );
}
