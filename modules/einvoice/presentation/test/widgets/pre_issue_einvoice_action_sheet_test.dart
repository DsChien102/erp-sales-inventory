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

    testWidgets('preview loading shows spinner and disabled items keep chevron',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(state: PreIssueSheetState.previewLoading),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Disabled items still show chevron-right (3 total: issue + send + trailing on other)
      // Loading item replaces chevron with spinner
      final chevrons = find.byWidgetPredicate(
        (w) => w is VIcon && (w as dynamic).icon == VIcons.chevronRight,
      );
      expect(chevrons, findsAtLeast(2));
    });

    testWidgets('buyer not ready shows warning banner and link button',
        (tester) async {
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
  });
}
