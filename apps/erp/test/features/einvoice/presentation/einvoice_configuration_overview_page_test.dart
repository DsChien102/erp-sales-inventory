import 'package:erp/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _CountingEinvoiceModule implements IEInvoiceModule {
  _CountingEinvoiceModule(this.delegate);

  final IEInvoiceModule delegate;
  int connectionScreenQueries = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is GetProviderConnectionScreenQuery) {
      connectionScreenQueries += 1;
    }
    return delegate.executeQueryAsync(query);
  }
}

void main() {
  testWidgets('reloads overview after returning from MISA connection', (tester) async {
    final module = _CountingEinvoiceModule(
      FakeEInvoiceModule(scenario: FakeEInvoiceScenario.configReadinessBlocked),
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: EInvoiceConfigurationOverviewPage(
          einvoiceModule: module,
          executionContext: FakeExecutionContext(),
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
    expect(module.connectionScreenQueries, 2);
  });
}
