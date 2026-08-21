import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  group('ResendInvoiceSheet', () {
    testWidgets('shows resend title, latest summary, history link, CTA',
        (tester) async {
      var historyTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: ResendInvoiceSheet(
              latestEmail: ResendInvoiceSheet.previewLatestEmail,
              latestDateTime: ResendInvoiceSheet.previewLatestDateTime,
              onSubmit: (_) {},
              onCancel: () {},
              onViewHistory: () => historyTapped = true,
            ),
          ),
        ),
      );

      expect(find.text(SendInvoiceCopy.resendTitle), findsOneWidget);
      expect(
        find.text(
          SendInvoiceCopy.latestDeliverySummary(
            email: ResendInvoiceSheet.previewLatestEmail,
            dateTime: ResendInvoiceSheet.previewLatestDateTime,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(SendInvoiceCopy.resendAction), findsOneWidget);
      expect(find.text(SendInvoiceCopy.viewHistoryLink), findsOneWidget);
      expect(find.text(ResendInvoiceSheet.previewLatestEmail), findsWidgets);

      await tester.tap(find.byKey(const Key('action_view_delivery_history')));
      await tester.pump();
      expect(historyTapped, isTrue);
    });
  });
}
