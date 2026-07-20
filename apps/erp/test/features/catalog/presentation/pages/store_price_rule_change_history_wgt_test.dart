import 'package:erp/features/catalog/presentation/pages/settings/store_price_rule_change_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

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

  testWidgets('wgt_e06_u02_hist_01 shows history from fake module', (tester) async {
    final fakeModule = FakeCatalogModule();
    await fakeModule.executeCommandAsync(
      SetStorePriceRuleCommand(
        tenantId: 'tenant-1',
        name: 'Mặc định bán lẻ',
        listMarkupRatio: 0.12,
        floorMarkupRatio: 0.10,
      ),
    );
    await fakeModule.executeCommandAsync(
      SetStorePriceRuleCommand(
        tenantId: 'tenant-1',
        name: 'Mặc định bán lẻ',
        listMarkupRatio: 0.15,
        floorMarkupRatio: 0.10,
      ),
    );

    getIt.registerSingleton<ICatalogModule>(fakeModule);
    getIt.registerSingleton<IExecutionContext>(_FakeExecutionContext());

    await tester.pumpWidget(
      const MaterialApp(home: StorePriceRuleChangeHistoryPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử thay đổi'), findsOneWidget);
    expect(find.text('Bởi: fake-user'), findsWidgets);
    expect(find.text('Hiện tại'), findsOneWidget);
    expect(find.text('+15.0%'), findsOneWidget);
  });
}
