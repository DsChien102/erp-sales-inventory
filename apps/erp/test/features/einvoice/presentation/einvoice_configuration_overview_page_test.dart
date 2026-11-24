import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart';

import '../support/fake_einvoice_configuration_repository.dart';

class _CountingRepository extends FakeEInvoiceConfigurationRepository {
  _CountingRepository({super.scenario = FakeEInvoiceConfigurationScenario.configReadinessReady});

  int connectionScreenQueries = 0;

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen() {
    connectionScreenQueries += 1;
    return super.getConnectionScreen();
  }
}

void main() {
  testWidgets('reloads overview after returning from MISA connection', (tester) async {
    final repository = _CountingRepository(
      scenario: FakeEInvoiceConfigurationScenario.configReadinessBlocked,
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: EInvoiceConfigurationOverviewPage(
          repository: repository,
          onConnectionTap: () async {
            opened = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kết nối MISA'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(repository.connectionScreenQueries, 2);
  });

  testWidgets('issuance card stays closed while MISA is disconnected', (tester) async {
    final repository = _CountingRepository(
      scenario: FakeEInvoiceConfigurationScenario.configReadinessBlocked,
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: EInvoiceConfigurationOverviewPage(
          repository: repository,
          onIssuanceTap: () async {
            opened = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cấu hình phát hành'));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    expect(repository.connectionScreenQueries, 1);
  });

  testWidgets('reloads overview after returning from issuance configuration', (tester) async {
    final repository = _CountingRepository(
      scenario: FakeEInvoiceConfigurationScenario.configReadinessReady,
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: EInvoiceConfigurationOverviewPage(
          repository: repository,
          onIssuanceTap: () async {
            opened = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cấu hình phát hành'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(repository.connectionScreenQueries, 2);
  });

  testWidgets('reloads overview after returning from automation policy configuration', (
    tester,
  ) async {
    final repository = _CountingRepository(
      scenario: FakeEInvoiceConfigurationScenario.configReadinessBlocked,
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: EInvoiceConfigurationOverviewPage(
          repository: repository,
          onAutomationTap: () async {
            opened = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tự động hóa'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(repository.connectionScreenQueries, 2);
  });
}
