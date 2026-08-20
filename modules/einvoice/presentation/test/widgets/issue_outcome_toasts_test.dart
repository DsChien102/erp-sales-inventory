import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  group('IssueSuccessToast', () {
    testWidgets('shows approved success message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Show',
                onPressed: () => IssueSuccessToast.show(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text(OrderEInvoiceCopy.issueSuccessMessage), findsOneWidget);
      final toast = tester.widget<VToast>(find.byType(VToast));
      expect(toast.type, VToastType.success);
      expect(toast.message, OrderEInvoiceCopy.issueSuccessMessage);
    });
  });

  group('IssueFailureToast', () {
    testWidgets('shows approved failure message with danger toast',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Show',
                onPressed: () => IssueFailureToast.show(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text(OrderEInvoiceCopy.issueFailureMessage), findsOneWidget);
      final toast = tester.widget<VToast>(find.byType(VToast));
      expect(toast.type, VToastType.danger);
      expect(toast.message, OrderEInvoiceCopy.issueFailureMessage);
    });
  });
}
