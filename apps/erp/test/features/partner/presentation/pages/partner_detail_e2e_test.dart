import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
      expect(find.textContaining('Trần Thị B'), findsWidgets);
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
