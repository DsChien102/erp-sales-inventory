import 'package:erp/features/sales/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  for (final phone in ['', '09881234', '098812345678', '0988abc123456']) {
    testWidgets('invalid phone "$phone" never reaches customer operations', (tester) async {
      var duplicateCalls = 0;
      var createCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => SalesCustomerQuickCreateSheet.show(
                  context,
                  checkDuplicate: (_) async {
                    duplicateCalls++;
                    return null;
                  },
                  createCustomer: (_, {required confirmDuplicate}) async {
                    createCalls++;
                    throw const SalesCustomerOperationException('Unexpected call');
                  },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('input_sg04_quick_name')), 'Customer');
      // Programmatic input bypasses formatters: submit must still validate it.
      final input = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('input_sg04_quick_phone')),
          matching: find.byType(TextField),
        ),
      );
      input.controller!.text = phone;
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(VFieldError), findsNothing);
      final submit = find.byKey(const Key('btn_sg04_quick_create_submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(duplicateCalls, 0);
      expect(createCalls, 0);
      expect(find.byType(VFieldError), findsOneWidget);
      await tester.enterText(find.byKey(const Key('input_sg04_quick_phone')), '098');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(VFieldError), findsNothing);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.byType(VFieldError), findsOneWidget);
      expect(duplicateCalls, 0);
      expect(createCalls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
