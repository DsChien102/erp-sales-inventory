import 'package:erp/features/einvoice/presentation/pages/automation_policy_page.dart';
import 'package:erp/features/einvoice/presentation/pages/default_issuance_configuration_page.dart';
import 'package:erp/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart';
import 'package:erp/features/einvoice/presentation/pages/invoice_delivery_history_page.dart';
import 'package:erp/features/einvoice/presentation/pages/provider_connection_page.dart';
import 'package:erp/features/einvoice/presentation/widgets/invoice_delivery_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/fake_einvoice_configuration_repository.dart';
import '../support/fake_einvoice_repository.dart';

void main() {
  final pages = <String, Widget Function()>{
    'HD-01 overview': () => EInvoiceConfigurationOverviewPage(
      repository: FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.configReadinessReady,
      ),
    ),
    'HD-02 provider connection': () => ProviderConnectionPage(
      repository: FakeEInvoiceConfigurationRepository(),
    ),
    'HD-04 default issuance': () => DefaultIssuanceConfigurationPage(
      repository: FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.listTemplatesOk,
      ),
    ),
    'HD-05 automation policy': () => AutomationPolicyPage(
      repository: FakeEInvoiceConfigurationRepository(),
    ),
    'HD-13 delivery history': () => InvoiceDeliveryHistoryPage(
      salesOrderId: 'order-101',
      repository: FakeEInvoiceRepository(),
    ),
  };

  Future<double> bodyWidth(
    WidgetTester tester,
    String name,
    Widget page,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: VTheme.lightTheme, home: page));
    await tester.pumpAndSettle();
    // HD-13 has no VPagePadding: measure its body view instead.
    final finder = name.startsWith('HD-13')
        ? find.byType(InvoiceDeliveryHistoryView).first
        : find.byType(VPagePadding).first;
    return tester.getSize(finder).width;
  }

  for (final entry in pages.entries) {
    testWidgets('${entry.key}: desktop body is 720 column', (tester) async {
      expect(await bodyWidth(tester, entry.key, entry.value(), const Size(1280, 800)), 720);
    });
    testWidgets('${entry.key}: phone body is full width', (tester) async {
      expect(await bodyWidth(tester, entry.key, entry.value(), const Size(390, 844)), 390);
    });
  }
}
