import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  const summary = IssueInvoiceConfirmationSummary.previewFixture;

  Widget buildSubject({
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: IssueInvoiceConfirmationSheet(
          summary: summary,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ),
    );
  }

  group('IssueInvoiceConfirmationSheet', () {
    testWidgets('shows title, summary lines, and actions', (tester) async {
      await tester.pumpWidget(buildSubject(onConfirm: () {}, onCancel: () {}));

      expect(
        find.text(OrderEInvoiceCopy.issueConfirmationTitle),
        findsOneWidget,
      );
      expect(
        find.text(
          OrderEInvoiceCopy.issueConfirmationSummaryLine1(
            orderReference: summary.orderReference,
            orderTotal: summary.orderTotal,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          OrderEInvoiceCopy.issueConfirmationSummaryLine2(
            templateNumber: summary.templateNumber,
            templateSymbol: summary.templateSymbol,
            authorityMode: summary.authorityMode,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(OrderEInvoiceCopy.issueConfirmationConfirm),
        findsOneWidget,
      );
      expect(
        find.text(OrderEInvoiceCopy.issueConfirmationCancel),
        findsOneWidget,
      );
    });

    testWidgets('cancel callback does not require navigator pop',
        (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        buildSubject(onConfirm: () {}, onCancel: () => cancelled = true),
      );

      await tester.tap(find.byKey(const Key('action_cancel_issue')));
      await tester.pump();

      expect(cancelled, isTrue);
      expect(find.byType(IssueInvoiceConfirmationSheet), findsOneWidget);
    });

    testWidgets('confirm via show helper returns true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: VButton(
                label: 'Open',
                onPressed: () async {
                  final confirmed = await showIssueInvoiceConfirmationSheet(
                    context,
                    summary: summary,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(confirmed ? 'confirmed' : 'cancelled')),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('action_confirm_issue')));
      await tester.pumpAndSettle();

      expect(find.text('confirmed'), findsOneWidget);
    });

    testWidgets('cancel via show helper returns false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: VButton(
                label: 'Open',
                onPressed: () async {
                  final confirmed = await showIssueInvoiceConfirmationSheet(
                    context,
                    summary: summary,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(confirmed ? 'confirmed' : 'cancelled')),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('action_cancel_issue')));
      await tester.pumpAndSettle();

      expect(find.text('cancelled'), findsOneWidget);
    });
  });
}
