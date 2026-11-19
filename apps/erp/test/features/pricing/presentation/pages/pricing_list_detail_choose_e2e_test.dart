import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../auth/support/scripted_auth.dart';
import '../../../dashboard/presentation/fake_default_pair_repository.dart';
import '../../../partner/support/partner_router_harness.dart';
import '../../pricing_e2e_harness.dart';

void main() {
  tearDown(() async {
    await tearDownPricingE2E();
  });

  group('e2e_e02_u01 — list/search (S2)', () {
    testWidgets(
      'e2e_e02_u01_fr01_01: list loads cards from searchRulesDefault',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
        expect(
          find.descendant(
            of: findByWgtKey('wgt_e02_u01_fr01_01'),
            matching: find.text('Giá riêng'),
          ),
          findsWidgets,
        );
        expect(find.byType(PriceRuleCard), findsWidgets);
        expect(find.text('Khách hàng mẫu'), findsWidgets);
      },
    );

    testWidgets(
      'e2e_e02_u01_fr01_02: empty tenant shows empty state',
      (tester) async {
        await setUpPricingE2E(
          searchScenario: FakePricingScenario.searchRulesEmpty,
        );
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        expect(find.text('Chưa có giá riêng nào'), findsOneWidget);
        expect(find.text('Tạo giá riêng để bắt đầu.'), findsOneWidget);
        expect(find.byType(VEmptyState), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_add_flow_opens_detail_after_create',
      (tester) async {
        final repo = await setUpPricingE2E(
          createScenario: FakePricingScenario.createRuleOk,
          detailScenario: FakePricingScenario.ruleDetailActive,
        );
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(VFloatingActionButton));
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);

        final cubit = tester
            .element(findByWgtKey('wgt_e02_u04_fr01_01'))
            .read<PriceRuleFormCubit>();
        cubit
          ..selectCustomer(
            customerId: 'customer-1',
            customerName: 'Khách hàng mẫu',
          )
          ..selectProduct(productId: 'product-1', productName: 'Vaccine mẫu')
          ..selectProductUnit(productUnitId: 'unit-1', productUnitName: 'Lọ')
          ..updatePrice(150000)
          ..updateDates(effectiveFrom: DateTime.utc(2026, 7, 16));

        await tester.pump();
        await cubit.submit();
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);

        final searchBeforeBack = repo.searchCalls;
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is VIcon && widget.icon == VIcons.arrowBack,
          ),
        );
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
        expect(repo.searchCalls, searchBeforeBack + 1);
      },
    );

    testWidgets(
      'wgt_list_fab_hidden_without_create',
      (tester) async {
        await setUpPricingE2E(
          searchScenario: FakePricingScenario.searchRulesEmpty,
          searchAvailableActions: const [],
        );
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        expect(find.byType(VFloatingActionButton), findsNothing);
        expect(find.text('Thêm giá riêng'), findsNothing);

        await setUpPricingE2E(
          searchScenario: FakePricingScenario.searchRulesEmpty,
          searchAvailableActions: const [PricingAvailableActions.createManual],
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing-test-origin'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mở Pricing'));
        await tester.pumpAndSettle();

        expect(find.byType(VFloatingActionButton), findsOneWidget);
        expect(find.text('Thêm giá riêng'), findsOneWidget);
      },
    );

    testWidgets(
      'router_edit_without_extra_goes_list',
      (tester) async {
        await setUpPricingE2E();
        final session = loginSession(store: PartnerSessionStore(const {}));
        session.applySignedInUser('user-1');
        GetIt.instance
          ..registerSingleton<SessionController>(session)
          ..registerSingleton<DefaultPairRepository>(
            FakeDefaultPairRepository(),
          );
        addTearDown(() {
          try {
            appRouter.go('/');
          } catch (_) {}
        });

        await tester.pumpWidget(
          MaterialApp.router(theme: VTheme.lightTheme, routerConfig: appRouter),
        );
        appRouter.go('/pricing/fake-rule-1/edit');
        await tester.pumpAndSettle();

        expect(
          Uri.parse(
            appRouter.routerDelegate.currentConfiguration.last.matchedLocation,
          ).path,
          '/pricing',
        );
        expect(findByWgtKey('wgt_e02_u01_fr01_01'), findsOneWidget);
      },
    );

    test('router_pricing_removed_routes', () {
      List<GoRoute> collectGoRoutes(List<RouteBase> routes) {
        final result = <GoRoute>[];
        for (final route in routes) {
          if (route is GoRoute) {
            result.add(route);
          }
          result.addAll(collectGoRoutes(route.routes));
        }
        return result;
      }

      final paths = collectGoRoutes(
        appRouter.configuration.routes,
      ).map((r) => r.path).toSet();
      expect(paths, isNot(contains('/pricing/choose-method')));
      expect(paths, isNot(contains('/pricing/import')));
      expect(paths, contains('/pricing'));
      expect(paths, contains('/pricing/new'));
    });
  });

  group('e2e_e02_u03 — detail (S3)', () {
    testWidgets(
      'e2e_e02_u03_fr01_01: list opens detail with Thao tác CTA',
      (tester) async {
        await setUpPricingE2E();
        await tester.pumpWidget(buildPricingRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Khách hàng mẫu').first);
        await tester.pumpAndSettle();

        expect(findByWgtKey('wgt_e02_u03_fr01_01'), findsOneWidget);
        expect(find.text('Thao tác'), findsOneWidget);
      },
    );

    testWidgets(
      'e2e_e02_u03_fr01_02: not-found detail shows empty state',
      (tester) async {
        await setUpPricingE2E(
          detailScenario: FakePricingScenario.ruleDetailNotFound,
        );
        await tester.pumpWidget(
          buildPricingRouter(initialLocation: '/pricing/missing-rule'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không tìm thấy'), findsOneWidget);
      },
    );
  });
}
