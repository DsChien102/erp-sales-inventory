import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({
    SendInvoiceSheetState state = SendInvoiceSheetState.suggested,
    String initialEmail = '',
    ValueChanged<String>? onSubmit,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: SendInvoiceSheet(
          invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
          invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          initialEmail: initialEmail,
          state: state,
          onSubmit: onSubmit ?? (_) {},
          onCancel: () {},
        ),
      ),
    );
  }

  group('SendInvoiceSheet', () {
    testWidgets('O01-A shows suggested email and identity', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: SendInvoiceSheetState.suggested,
          initialEmail: SendInvoiceSheet.previewSuggestedEmail,
        ),
      );

      expect(find.text(SendInvoiceCopy.sendTitle), findsOneWidget);
      expect(
        find.text(
          SendInvoiceCopy.invoiceIdentity(
            invoiceNumber: SendInvoiceSheet.previewInvoiceNumber,
            invoiceSymbol: SendInvoiceSheet.previewInvoiceSymbol,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(SendInvoiceSheet.previewSuggestedEmail), findsOneWidget);
      expect(find.text(SendInvoiceCopy.recipientHelper), findsOneWidget);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNotNull);
      expect(send.isLoading, isFalse);
    });

    testWidgets('O01-B empty disables submit', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: SendInvoiceSheetState.empty),
      );

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNull);
      expect(find.text(SendInvoiceCopy.recipientHelper), findsOneWidget);
    });

    testWidgets('O01-C shows invalid helper and disables submit', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: SendInvoiceSheetState.invalid,
          initialEmail: 'bad',
        ),
      );

      expect(find.text(SendInvoiceCopy.recipientInvalid), findsOneWidget);
      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNull);
    });

    testWidgets('O01-D locks field, shows loading, blocks repeat submit', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        buildSubject(
          state: SendInvoiceSheetState.loading,
          initialEmail: SendInvoiceSheet.previewSuggestedEmail,
          onSubmit: (_) => submitted++,
        ),
      );

      expect(find.text(SendInvoiceCopy.recipientHelper), findsOneWidget);
      expect(find.text(SendInvoiceCopy.sendAction), findsOneWidget);

      final field = tester.widget<VTextField>(
        find.byKey(const Key('field_recipient_email')),
      );
      expect(field.enabled, isFalse);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.isLoading, isTrue);
      expect(send.onPressed, isNull);

      await tester.tap(find.byKey(const Key('action_send_invoice')));
      await tester.pump();
      expect(submitted, 0);
    });

    testWidgets('valid email after invalid restores helper', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: SendInvoiceSheetState.invalid,
          initialEmail: 'bad',
        ),
      );

      expect(find.text(SendInvoiceCopy.recipientInvalid), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('field_recipient_email')),
        'ok@company.com',
      );
      await tester.pump();

      expect(find.text(SendInvoiceCopy.recipientHelper), findsOneWidget);
      expect(find.text(SendInvoiceCopy.recipientInvalid), findsNothing);

      final send = tester.widget<VButton>(
        find.byKey(const Key('action_send_invoice')),
      );
      expect(send.onPressed, isNotNull);
    });
  });
}
