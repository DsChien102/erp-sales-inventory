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
import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    required FakePartnerRepository partnerModule,
    required List<String> permissions,
    // INTERIM: any member (role != null) has full feature access. Pass
    // role: null to simulate a non-member (feature screens are locked).
    String? role = 'staff',
  }) {
    final session = SessionStore();
    if (role != null) {
      session.apply(
        SessionPrincipal(
          userId: 'user-1',
          tenantId: 'tenant-1',
          role: role,
          isOwner: false,
          permissions: permissions,
        ),
      );
    }

    getIt
      ..registerSingleton<PartnerRepository>(partnerModule)
      ..registerSingleton<SessionController>(
        SessionController(repository: FakeSessionRepository(), store: session),
      );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PartnerListPage(),
        ),
        GoRoute(
          path: '/partner/new',
          builder: (context, state) {
            final partnerType = state.extra as PartnerType;
            return PartnerCreatePage(
              partnerType: partnerType,
              repository: partnerModule,
              onCreated: (partnerId) => context.pop(partnerId),
              onOpenExisting: (_) {},
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('wgt_e01_u02_fr01_02: FAB opens create action sheet', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        partnerModule: FakePartnerRepository(scenario: FakePartnerScenario.searchEmpty),
        permissions: const [
          PartnerPermissions.view,
          PartnerPermissions.create,
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_02')), findsOneWidget);
    expect(find.byKey(const Key('btn_create_partner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_create_partner')));
    await tester.pumpAndSettle();

    expect(find.text('Thêm KH & NCC mới'), findsOneWidget);
    expect(find.text('Tạo cá nhân'), findsOneWidget);
    expect(find.text('Tạo tổ chức'), findsOneWidget);
  });

  testWidgets('wgt_e01_u02_scn07_01: locks the screen for a non-member', (
    tester,
  ) async {
    // INTERIM policy: a user with no tenant membership (role == null) has no
    // feature access, so the partner screen shows the locked state.
    await tester.pumpWidget(
      buildTestableWidget(
        partnerModule: FakePartnerRepository(scenario: FakePartnerScenario.searchEmpty),
        role: null,
        permissions: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_create_partner')), findsNothing);
    expect(find.text('Bạn không có quyền xem\nKH & NCC'), findsOneWidget);
  });

  testWidgets('wgt_e01_u02_fr01_03: selecting organization opens create page', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        partnerModule: FakePartnerRepository(scenario: FakePartnerScenario.searchEmpty),
        permissions: const [
          PartnerPermissions.view,
          PartnerPermissions.create,
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_create_partner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner_create_organization')));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tổ chức'), findsWidgets);
    expect(find.text('3. Thông tin tổ chức'), findsOneWidget);
  });
}
