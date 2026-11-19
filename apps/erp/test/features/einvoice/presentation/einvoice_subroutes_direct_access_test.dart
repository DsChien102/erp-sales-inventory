import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/presentation/pages/automation_policy_page.dart';
import 'package:erp/features/einvoice/presentation/pages/default_issuance_configuration_page.dart';
import 'package:erp/features/einvoice/presentation/pages/provider_connection_page.dart';

import '../support/fake_einvoice_configuration_repository.dart';

class _ForbiddenConfigurationRepository extends FakeEInvoiceConfigurationRepository {
  final List<String> writes = [];
  final List<String> reads = [];

  AppException _deny() => const AppException(EInvoiceErrorCodes.noPermission);

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen() {
    reads.add('getConnectionScreen');
    throw _deny();
  }

  @override
  Future<List<ProviderTemplateDto>> listTemplates({
    bool? invoiceWithCode,
    int? year,
  }) {
    reads.add('listTemplates');
    throw _deny();
  }

  @override
  Future<IssuanceProfileDto> getIssuanceProfile() {
    reads.add('getIssuanceProfile');
    throw _deny();
  }

  @override
  Future<AutomationPolicyDto> getAutomationPolicy() {
    reads.add('getAutomationPolicy');
    throw _deny();
  }

  @override
  Future<ConfigurationReadinessDto> getConfigurationReadiness({
    IssuancePurpose? purpose,
  }) {
    reads.add('getConfigurationReadiness');
    throw _deny();
  }

  @override
  Future<ProviderConnectionResultDto> connect({
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) {
    writes.add('connect');
    throw _deny();
  }

  @override
  Future<ProviderConnectionResultDto> reconnect({
    required String connectionId,
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) {
    writes.add('reconnect');
    throw _deny();
  }

  @override
  Future<ProviderConnectionResultDto> disconnect({
    required String connectionId,
    required bool confirm,
  }) {
    writes.add('disconnect');
    throw _deny();
  }

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) {
    writes.add('setDefaultConfiguration');
    throw _deny();
  }

  @override
  Future<AutomationPolicyDto> updateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) {
    writes.add('updateAutomationPolicy');
    throw _deny();
  }
}

void main() {
  group('Direct sub-route access without manageConfiguration permission', () {
    testWidgets(
      'ProviderConnectionPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final repository = _ForbiddenConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: ProviderConnectionPage(
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(repository.writes, isEmpty);
      },
    );

    testWidgets(
      'DefaultIssuanceConfigurationPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final repository = _ForbiddenConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: DefaultIssuanceConfigurationPage(
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(repository.writes, isEmpty);
      },
    );

    testWidgets(
      'AutomationPolicyPage renders permission denied state and sends no mutation commands',
      (tester) async {
        final repository = _ForbiddenConfigurationRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: AutomationPolicyPage(
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
        expect(repository.writes, isEmpty);
      },
    );
  });
}
