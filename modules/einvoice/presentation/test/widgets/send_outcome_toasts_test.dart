import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';

void main() {
  group('SendSuccessToast', () {
    testWidgets('shows approved success message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Show',
                onPressed: () => SendSuccessToast.show(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      final toast = tester.widget<VToast>(find.byType(VToast));
      expect(toast.type, VToastType.success);
      expect(toast.message, SendInvoiceCopy.sendSuccessMessage);
    });
  });

  group('SendFailureToast', () {
    testWidgets('shows approved failure message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => VButton(
                label: 'Show',
                onPressed: () => SendFailureToast.show(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      final toast = tester.widget<VToast>(find.byType(VToast));
      expect(toast.type, VToastType.danger);
      expect(toast.message, SendInvoiceCopy.sendFailureMessage);
    });
  });
}
