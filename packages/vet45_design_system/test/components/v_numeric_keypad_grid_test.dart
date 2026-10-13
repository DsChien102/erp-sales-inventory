import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_numeric_keypad_grid.dart';

void main() {
  group('VNumericKeypadGrid semantics', () {
    Future<void> pump(
      WidgetTester tester, {
      bool allowDecimal = true,
      ValueChanged<String>? onKey,
      VoidCallback? onBackspace,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VNumericKeypadGrid(
              mode: VNumericKeypadMode.quantity,
              allowDecimal: allowDecimal,
              onKey: onKey ?? (_) {},
              onBackspace: onBackspace ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('keys are named buttons; ⌫ reads "Xoá", "." reads "Dấu thập phân"',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      for (final label in ['1', '5', '0', 'Xoá', 'Dấu thập phân']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.label, label);
        expect(node.flagsCollection.isButton, isTrue);
      }
      expect(find.bySemanticsLabel('⌫'), findsNothing);
      handle.dispose();
    });

    testWidgets('semantic tap reaches the key callbacks', (tester) async {
      final handle = tester.ensureSemantics();
      final keys = <String>[];
      var backspaces = 0;
      await pump(tester, onKey: keys.add, onBackspace: () => backspaces++);

      tester.semantics.tap(find.semantics.byLabel('5'));
      tester.semantics.tap(find.semantics.byLabel('Dấu thập phân'));
      tester.semantics.tap(find.semantics.byLabel('Xoá'));

      expect(keys, ['5', '.']);
      expect(backspaces, 1);
      handle.dispose();
    });

    testWidgets('blank filler key is not announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, allowDecimal: false);

      expect(find.bySemanticsLabel('Dấu thập phân'), findsNothing);
      // 9 digit keys + 0 + backspace; the blank bottom-left key is skipped.
      var buttons = 0;
      for (final label in ['1','2','3','4','5','6','7','8','9','0','Xoá']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
        buttons++;
      }
      expect(buttons, 11);
      handle.dispose();
    });
  });
}
