import 'package:erp/features/einvoice/presentation/pages/automation_policy_page.dart';
import 'package:erp/features/einvoice/presentation/pages/default_issuance_configuration_page.dart';
import 'package:erp/features/einvoice/presentation/pages/provider_connection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _ForbiddenEinvoiceModule implements IEInvoiceModule {
  final List<ICommand<dynamic>> executedCommands = [];
  final List<IQuery<dynamic>> executedQueries = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    executedCommands.add(command);
    throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    executedQueries.add(query);
    throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
  }
}

void main() {
  group('Direct sub-route access without manageConfiguration permission', () {
    testWidgets(
      'ProviderConnectionPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final module = _ForbiddenEinvoiceModule();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: ProviderConnectionPage(
              einvoiceModule: module,
              executionContext: FakeExecutionContext(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(module.executedCommands, isEmpty);
      },
    );

    testWidgets(
      'DefaultIssuanceConfigurationPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final module = _ForbiddenEinvoiceModule();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: DefaultIssuanceConfigurationPage(
              einvoiceModule: module,
              executionContext: FakeExecutionContext(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(module.executedCommands, isEmpty);
      },
    );

    testWidgets(
      'AutomationPolicyPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final module = _ForbiddenEinvoiceModule();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: AutomationPolicyPage(
              einvoiceModule: module,
              executionContext: FakeExecutionContext(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(module.executedCommands, isEmpty);
      },
    );
  });
}
