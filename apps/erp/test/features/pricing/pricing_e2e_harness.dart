import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_detail_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_form_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_history_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import 'support/fake_customer_price_rule_repository.dart';
import 'support/fake_pricing_backend.dart';

export 'support/fake_customer_price_rule_repository.dart';
export 'support/fake_pricing_backend.dart';

Future<FakeCustomerPriceRuleRepository> setUpPricingE2E({
  FakePricingScenario searchScenario = FakePricingScenario.searchRulesDefault,
  List<String>? searchAvailableActions,
  FakePricingScenario detailScenario = FakePricingScenario.ruleDetailActive,
  FakePricingScenario historyScenario = FakePricingScenario.historyMixedSources,
  FakePricingScenario createScenario = FakePricingScenario.createRuleOk,
  FakePricingScenario updateScenario = FakePricingScenario.updateRuleOk,
  FakePricingScenario disableScenario = FakePricingScenario.disableRuleOk,
  FakePricingScenario reenableScenario = FakePricingScenario.reenableOk,
  FakePricingScenario reenablePrecheckScenario =
      FakePricingScenario.reenablePrecheckValid,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();

  final repo = FakeCustomerPriceRuleRepository(
    searchScenario: searchScenario,
    searchAvailableActions: searchAvailableActions,
    detailScenario: detailScenario,
    historyScenario: historyScenario,
    createScenario: createScenario,
    updateScenario: updateScenario,
    disableScenario: disableScenario,
    reenableScenario: reenableScenario,
    reenablePrecheckScenario: reenablePrecheckScenario,
  );

  getIt.registerSingleton<CustomerPriceRuleRepository>(repo);

  return repo;
}

Future<void> tearDownPricingE2E() async {
  await GetIt.instance.reset();
}

Widget buildPricingRouter({
  String initialLocation = '/pricing',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/pricing-test-origin',
        builder: (context, state) => Scaffold(
          body: Center(
            child: VButton(
              label: 'Mở Pricing',
              onPressed: () => context.push('/pricing'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingListPage(),
      ),
      GoRoute(
        path: '/pricing/new',
        builder: (context, state) => const PricingFormPage(),
      ),
      GoRoute(
        path: '/pricing/:ruleId',
        builder: (context, state) {
          final ruleId = state.pathParameters['ruleId']!;
          return PricingDetailPage(ruleId: ruleId);
        },
      ),
      GoRoute(
        path: '/pricing/:ruleId/edit',
        builder: (context, state) {
          final rule = state.extra as CustomerPriceRuleDetailDto?;
          if (rule == null) {
            return const Scaffold(
              body: Center(child: Text('missing rule extra')),
            );
          }
          return PricingFormPage(initialRule: rule);
        },
      ),
      GoRoute(
        path: '/pricing/:ruleId/history',
        builder: (context, state) {
          final ruleId = state.pathParameters['ruleId']!;
          return PricingHistoryPage(ruleId: ruleId);
        },
      ),
    ],
  );

  return MaterialApp.router(
    theme: VTheme.lightTheme,
    routerConfig: router,
  );
}

Future<CustomerPriceRuleDetailDto> loadFakeDetail({
  FakePricingScenario scenario = FakePricingScenario.ruleDetailActive,
  String ruleId = 'fake-rule-1',
}) {
  return FakeCustomerPriceRuleRepository(detailScenario: scenario).getDetail(
    ruleId: ruleId,
    businessDate: DateTime.utc(2026, 7, 16),
  );
}

Finder findByWgtKey(String id) => find.byKey(Key(id));
