import 'package:erp/features/catalog/presentation/pages/product_change_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_application/application.dart' hide ProductChangeHistoryPage;
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestWidget({required String scenarioId, String productId = 'product-1'}) {
    final fakeModule = FakeCatalogModule(scenario: scenarioId);
    
    getIt.registerSingleton<ICatalogModule>(fakeModule);
    getIt.registerSingleton<IExecutionContext>(_FakeExecutionContext());

    final router = GoRouter(
      initialLocation: '/change-history',
      routes: [
        GoRoute(
          path: '/change-history',
          builder: (context, state) => ProductChangeHistoryPage(
            productId: productId,
            productName: 'Thuốc A',
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('ProductChangeHistoryPage', () {
    testWidgets('renders history items when successful (scn_contract_e07_u04_fr02_01)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        scenarioId: FakeCatalogScenario.scnContractE07U04Fr02_01,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Lịch sử thay đổi'), findsOneWidget);
      expect(find.text('Thuốc A'), findsOneWidget);
      
      // Look for an item
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders empty state when no history (scn_contract_e07_u04_fr02_02)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        scenarioId: FakeCatalogScenario.scnContractE07U04Fr02_02,
        productId: 'product-6',
      ));

      await tester.pumpAndSettle();

      expect(find.text('Chưa có lịch sử thay đổi nào'), findsOneWidget);
    });

    testWidgets('shows error state when permission denied (scn_contract_e07_u04_fr03_01)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        scenarioId: FakeCatalogScenario.scnContractE07U04Fr03_01,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
