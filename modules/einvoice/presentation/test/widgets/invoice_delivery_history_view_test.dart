import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  group('InvoiceDeliveryHistoryView', () {
    testWidgets('shows issued badge, section, success/failure/auto rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: InvoiceDeliveryHistoryView(
              summary: InvoiceDeliveryHistorySummary.preview,
              rows: InvoiceDeliveryHistoryView.previewRows,
            ),
          ),
        ),
      );

      expect(find.text(SendInvoiceCopy.issuedBadge), findsOneWidget);
      expect(find.text(SendInvoiceCopy.historySectionTitle), findsOneWidget);
      expect(
        find.text(
          SendInvoiceCopy.deliveryMainText(
            success: true,
            email: 'accounting@company.com',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          SendInvoiceCopy.deliveryMainText(
            success: false,
            email: 'accounting@company.com',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(SendInvoiceCopy.actorAutomatic),
        findsOneWidget,
      );
    });
  });
}
