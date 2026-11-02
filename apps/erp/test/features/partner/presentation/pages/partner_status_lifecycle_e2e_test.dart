import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
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
import '../../support/fake_partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';
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
    required FakePartnerRepository partnerModule,
    required List<String> permissions,
    String initialLocation = '/partner/p-person-1',
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
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
      )
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
          path: '/partner',
          builder: (context, state) => const PartnerListPage(),
        ),
        GoRoute(
          path: '/partner/:partnerId',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            return PartnerDetailPage(
              partnerId: partnerId,
              repository: partnerModule,
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  const statusPermissions = [
    PartnerPermissions.detailView,
    PartnerPermissions.statusManage,
    PartnerPermissions.delete,
  ];

  testWidgets(
    'e2e_e02_u01_fr01_01: deactivate shows inactive banner on detail',
    (tester) async {
      final module = FakePartnerRepository(
        scenario: FakePartnerScenario.detailPersonActive,
      );

      await tester.pumpWidget(
        buildRouter(
          partnerModule: module,
          permissions: statusPermissions,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngừng hoạt động'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr05_01')), findsOneWidget);
      await tester.tap(find.byKey(const Key('deactivate_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Ngừng hoạt động'), findsWidgets);
      expect(
        find.text(PartnerDetailInactiveBanner.message),
        findsOneWidget,
      );
      expect(find.byKey(const Key('wgt_e02_u01_fr02_01')), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e02_u01_fr03_01: reactivate restores active status',
    (tester) async {
      final module = FakePartnerRepository(
        scenario: FakePartnerScenario.detailPersonActive,
      );
      // Seed inactive via deactivate command path used by fake overrides.
      await module.deactivate('p-person-1', expectedVersion: 1);

      await tester.pumpWidget(
        buildRouter(
          partnerModule: module,
          permissions: statusPermissions,
          initialLocation: '/partner/p-person-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr02_01')), findsOneWidget);

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kích hoạt lại'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr03_01')), findsOneWidget);
      await tester.tap(find.byKey(const Key('reactivate_confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u01_fr02_01')), findsNothing);
      expect(find.text('Đang hoạt động'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e02_u02_fr01_01: soft delete pops to list after confirm',
    (tester) async {
      final module = FakePartnerRepository(
        scenario: FakePartnerScenario.detailPersonActive,
      );

      await tester.pumpWidget(
        buildRouter(
          partnerModule: module,
          permissions: statusPermissions,
          initialLocation: '/partner/p-person-1',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u02_fr05_01')), findsOneWidget);
      await tester.tap(find.byKey(const Key('soft_delete_confirm')));
      await tester.pumpAndSettle();

      expect(find.byType(PartnerListPage), findsOneWidget);
      expect(find.byType(PartnerDetailPage), findsNothing);
    },
  );

  testWidgets(
    'e2e_e02_u02_fr04_01: HAS_TRANSACTIONS shows D-09 blocked sheet',
    (tester) async {
      await tester.pumpWidget(
        buildRouter(
          partnerModule: FakePartnerRepository(
            scenario: FakePartnerScenario.softDeleteNotEligible,
          ),
          permissions: statusPermissions,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa hồ sơ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e02_u02_fr04_01')), findsOneWidget);
      expect(find.text('Không thể xóa hồ sơ'), findsOneWidget);
      expect(find.byKey(const Key('delete_blocked_deactivate')), findsOneWidget);
    },
  );
}
