import 'package:erp/features/pricing/presentation/pages/pricing_choose_method_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_detail_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_form_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_history_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_import_page.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_list_page.dart';
import 'package:erp/features/pricing/presentation/services/pricing_import_file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// Composes [FakePricingModule] per command/query family so multi-page E2E
/// flows can search + detail + mutate without a single-scenario UnsupportedError.
final class PricingE2eModule implements IPricingModule {
  PricingE2eModule({
    this.searchScenario = FakePricingScenario.searchRulesDefault,
    this.detailScenario = FakePricingScenario.ruleDetailActive,
    this.historyScenario = FakePricingScenario.historyMixedSources,
    this.createScenario = FakePricingScenario.createRuleOk,
    this.updateScenario = FakePricingScenario.updateRuleOk,
    this.disableScenario = FakePricingScenario.disableRuleOk,
    this.reenableScenario = FakePricingScenario.reenableOk,
    this.reenablePrecheckScenario = FakePricingScenario.reenablePrecheckValid,
    this.importStartScenario = FakePricingScenario.importReadyMixed,
    this.importConfirmScenario = FakePricingScenario.importConfirmPartial,
    this.importTemplateScenario = FakePricingScenario.importTemplateV1,
    this.memoryScenario = FakePricingScenario.memoryCreateOk,
  });

  final FakePricingScenario searchScenario;
  final FakePricingScenario detailScenario;
  final FakePricingScenario historyScenario;
  final FakePricingScenario createScenario;
  final FakePricingScenario updateScenario;
  final FakePricingScenario disableScenario;
  final FakePricingScenario reenableScenario;
  final FakePricingScenario reenablePrecheckScenario;
  final FakePricingScenario importStartScenario;
  final FakePricingScenario importConfirmScenario;
  final FakePricingScenario importTemplateScenario;
  final FakePricingScenario memoryScenario;
  final List<ICommand<dynamic>> commands = [];

  FakePricingModule _fake(FakePricingScenario scenario) => FakePricingModule(scenario: scenario);

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    commands.add(command);
    return switch (command) {
      CreateCustomerPriceRuleCommand _ => _fake(createScenario).executeCommandAsync(command),
      UpdateCustomerPriceRuleCommand _ => _fake(updateScenario).executeCommandAsync(command),
      DisableCustomerPriceRuleCommand _ => _fake(disableScenario).executeCommandAsync(command),
      ReenableCustomerPriceRuleCommand _ => _fake(reenableScenario).executeCommandAsync(command),
      StartCustomerPriceRuleImportCommand _ => _fake(
        importStartScenario,
      ).executeCommandAsync(command),
      ConfirmCustomerPriceRuleImportCommand _ => _fake(
        importConfirmScenario,
      ).executeCommandAsync(command),
      CancelCustomerPriceRuleImportCommand _ => _fake(
        FakePricingScenario.importCancelOk,
      ).executeCommandAsync(command),
      SaveRememberedPriceFromOrderCommand _ => _fake(memoryScenario).executeCommandAsync(command),
      _ => throw UnsupportedError(
        'PricingE2eModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchCustomerPriceRulesQuery _ => _fake(searchScenario).executeQueryAsync(query),
      GetCustomerPriceRuleDetailQuery _ => _fake(detailScenario).executeQueryAsync(query),
      GetCustomerPriceRuleHistoryQuery _ => _fake(historyScenario).executeQueryAsync(query),
      PrecheckCustomerPriceRuleReenableQuery _ => _fake(
        reenablePrecheckScenario,
      ).executeQueryAsync(query),
      GetCustomerPriceRuleImportTemplateQuery _ => _fake(
        importTemplateScenario,
      ).executeQueryAsync(query),
      GetCustomerPriceRuleImportQuery _ => _fake(importStartScenario).executeQueryAsync(query),
      _ => throw UnsupportedError(
        'PricingE2eModule: unsupported query ${query.runtimeType}',
      ),
    };
  }
}

Future<PricingE2eModule> setUpPricingE2E({
  FakePricingScenario searchScenario = FakePricingScenario.searchRulesDefault,
  FakePricingScenario detailScenario = FakePricingScenario.ruleDetailActive,
  FakePricingScenario historyScenario = FakePricingScenario.historyMixedSources,
  FakePricingScenario createScenario = FakePricingScenario.createRuleOk,
  FakePricingScenario updateScenario = FakePricingScenario.updateRuleOk,
  FakePricingScenario disableScenario = FakePricingScenario.disableRuleOk,
  FakePricingScenario reenableScenario = FakePricingScenario.reenableOk,
  FakePricingScenario reenablePrecheckScenario = FakePricingScenario.reenablePrecheckValid,
  FakePricingScenario importStartScenario = FakePricingScenario.importReadyMixed,
  FakePricingScenario importConfirmScenario = FakePricingScenario.importConfirmPartial,
  FakePricingScenario memoryScenario = FakePricingScenario.memoryCreateOk,
  IExecutionContext? executionContext,
}) async {
  final getIt = GetIt.instance;
  await getIt.reset();

  final module = PricingE2eModule(
    searchScenario: searchScenario,
    detailScenario: detailScenario,
    historyScenario: historyScenario,
    createScenario: createScenario,
    updateScenario: updateScenario,
    disableScenario: disableScenario,
    reenableScenario: reenableScenario,
    reenablePrecheckScenario: reenablePrecheckScenario,
    importStartScenario: importStartScenario,
    importConfirmScenario: importConfirmScenario,
    memoryScenario: memoryScenario,
  );

  getIt
    ..registerSingleton<IExecutionContext>(
      executionContext ?? FakeExecutionContext(tenantId: 'test-tenant-id'),
    )
    ..registerSingleton<IPricingModule>(module);

  return module;
}

Future<void> tearDownPricingE2E() async {
  await GetIt.instance.reset();
}

Widget buildPricingRouter({
  String initialLocation = '/pricing',
  PricingImportFileService importFileService = const DevicePricingImportFileService(),
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
        path: '/pricing/choose-method',
        builder: (context, state) => const PricingChooseMethodPage(),
      ),
      GoRoute(
        path: '/pricing/new',
        builder: (context, state) => const PricingFormPage(),
      ),
      GoRoute(
        path: '/pricing/import',
        builder: (context, state) => PricingImportPage(fileService: importFileService),
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
  return FakePricingModule(scenario: scenario).executeQueryAsync(
    GetCustomerPriceRuleDetailQuery(
      tenantId: 'test-tenant-id',
      ruleId: ruleId,
      businessDate: DateTime.utc(2026, 7, 16),
    ),
  );
}

Finder findByWgtKey(String id) => find.byKey(Key(id));
