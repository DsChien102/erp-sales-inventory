import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  Widget buildSubject({PreIssueSheetState state = const PreIssueSheetState()}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: PreIssueEInvoiceActionSheet(state: state),
      ),
    );
  }

  group('PreIssueEInvoiceActionSheet', () {
    testWidgets('idle state shows all actions', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text(OrderEInvoiceCopy.sheetTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.issueTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.previewTitle), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.sendTitle), findsOneWidget);
    });

    testWidgets('preview loading shows spinner and disables issue', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: PreIssueSheetState.previewLoading),
      );

      expect(find.byType(VLoading), findsOneWidget);

      final preview = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_preview')),
      );
      expect(preview.loading, isTrue);
      expect(preview.onTap, isNull);

      final issue = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_issue')),
      );
      expect(issue.enabled, isFalse);
      expect(issue.onTap, isNull);

      final send = tester.widget<EInvoiceActionItem>(
        find.byKey(const Key('action_send')),
      );
      expect(send.enabled, isFalse);
    });

    testWidgets('preview callback keeps sheet open', (tester) async {
      var previewTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PreIssueEInvoiceActionSheet(
              onPreview: () => previewTaps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('action_preview')));
      await tester.pump();

      expect(previewTaps, 1);
      expect(find.byType(PreIssueEInvoiceActionSheet), findsOneWidget);
    });

    testWidgets('buyer not ready shows warning banner and link button', (tester) async {
      await tester.pumpWidget(
        buildSubject(state: PreIssueSheetState.buyerNotReady),
      );

      expect(find.text(OrderEInvoiceCopy.buyerWarningTitle), findsOneWidget);
      expect(
        find.text(OrderEInvoiceCopy.buyerCorrectionAction),
        findsOneWidget,
      );
      expect(find.byType(VButton), findsOneWidget);
      expect(
        find.text(OrderEInvoiceCopy.issueDisabledSupporting),
        findsOneWidget,
      );
    });

    testWidgets('failed state shows failure banner while keeping issue action enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          state: const PreIssueSheetState(
            isFailed: true,
            failureCode: 'COMMAND_INTEGRITY',
          ),
        ),
      );

      expect(find.byType(IssuanceFailureBanner), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.failureBannerIntegrityMessage), findsOneWidget);
      expect(find.text(OrderEInvoiceCopy.issueTitle), findsOneWidget);
    });
  });
}
