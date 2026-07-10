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
import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    required FakePartnerModule partnerModule,
    required List<String> permissions,
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
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
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
        partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchEmpty),
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

  testWidgets('wgt_e01_u02_scn07_01: hides create FAB without partner.create', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchEmpty),
        permissions: const [PartnerPermissions.view],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_create_partner')), findsNothing);
    expect(find.text('Chưa có KH & NCC'), findsOneWidget);
  });

  testWidgets('wgt_e01_u02_fr01_03: selecting organization opens create page', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        partnerModule: FakePartnerModule(scenario: FakePartnerScenario.searchEmpty),
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
