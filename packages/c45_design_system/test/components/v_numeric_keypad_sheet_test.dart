import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:c45_design_system/src/components/v_numeric_keypad_grid.dart';
import 'package:c45_design_system/src/components/v_text_field_focus_ring.dart';

void main() {
  group('VNumericKeypadSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      required VNumericKeypadMode mode,
      String initialRaw = '',
      required ValueChanged<String> onSave,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VNumericKeypadSheet(
              mode: mode,
              initialRaw: initialRaw,
              onCancel: () {},
              onSave: onSave,
            ),
          ),
        ),
      );
    }

    testWidgets('display allows hardware keyboard without soft IME', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        onSave: (_) {},
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isFalse);
      expect(field.keyboardType, TextInputType.none);

      await tester.enterText(find.byType(TextField), '1000');
      await tester.pump();
      expect(field.controller!.text, '1,000');
    });

    testWidgets('keypad tap restarts caret blink (cursor visible)', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '1',
        onSave: (_) {},
      );
      await tester.pump();

      final editable = tester.state<EditableTextState>(find.byType(EditableText));
      // Advance into the "off" half of the blink cycle.
      await tester.pump(editable.cursorBlinkInterval);
      expect(editable.cursorCurrentlyVisible, isFalse);

      await tester.tap(
        find.descendant(of: find.byType(VNumericKeypadGrid), matching: find.text('2')),
      );
      await tester.pump();

      expect(editable.cursorCurrentlyVisible, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12',
      );
    });

    testWidgets('keeps display focused when tapping anywhere inside the sheet', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '12',
        onSave: (_) {},
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      final focusNode = field.focusNode!;
      final controller = field.controller!;
      expect(focusNode.hasFocus, isTrue);
      expect(controller.selection.isCollapsed, isTrue);

      Finder key(String label) => find.descendant(
        of: find.byType(VNumericKeypadGrid),
        matching: find.text(label),
      );

      await tester.tap(key('3'));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.text, '123');

      await tester.tap(find.text('Nhập số tiền'));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.text, '123');

      await tester.tap(find.text('Hủy'));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, '123');
    });

    testWidgets('unfocuses display when tapping outside the sheet TapRegion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: ColoredBox(color: Color(0xFFEEEEEE))),
                VNumericKeypadSheet(
                  mode: VNumericKeypadMode.money,
                  initialRaw: '9',
                  onCancel: () {},
                  onSave: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final focusNode = tester.widget<TextField>(find.byType(TextField)).focusNode!;
      expect(focusNode.hasFocus, isTrue);

      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('money shows comma thousands and suffix đ; field has no đ in text', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '1234',
        onSave: (_) {},
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '1,234');
      expect(find.text('đ'), findsOneWidget);
      expect(field.controller!.text.contains('đ'), isFalse);
      expect(find.byType(VTextFieldFocusRing), findsNothing);
    });

    testWidgets('money formats live while typing', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        onSave: (_) {},
      );
      await tester.pump();

      Finder key(String label) => find.descendant(
        of: find.byType(VNumericKeypadGrid),
        matching: find.text(label),
      );

      for (final d in ['1', '0', '0', '0']) {
        await tester.tap(key(d));
        await tester.pump();
      }

      final controller = tester.widget<TextField>(find.byType(TextField)).controller!;
      expect(controller.text, '1,000');
    });

    testWidgets('inserts digit at caret in the middle', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '15',
        onSave: (_) {},
      );
      await tester.pump();

      final controller = tester.widget<TextField>(find.byType(TextField)).controller!;
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();

      await tester.tap(find.text('9'));
      await tester.pump();

      expect(controller.text, '195');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('backspace deletes selection range in money digits', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '1234',
        onSave: (_) {},
      );
      await tester.pump();

      final controller = tester.widget<TextField>(find.byType(TextField)).controller!;
      // '1,234' — select ',23' (indices 1..4) → digits 2,3
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      await tester.pump();

      await tester.tap(find.text('⌫'));
      await tester.pump();

      expect(controller.text, '14');
      expect(controller.selection.baseOffset, 1);
    });

    testWidgets('onSave returns raw without formatting', (tester) async {
      String? saved;
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.money,
        initialRaw: '1000',
        onSave: (raw) => saved = raw,
      );
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1,000',
      );

      await tester.tap(find.text('Lưu'));
      await tester.pump();

      expect(saved, '1000');
    });

    testWidgets('quantity accepts decimal via keypad', (tester) async {
      await pumpSheet(
        tester,
        mode: VNumericKeypadMode.quantity,
        onSave: (_) {},
      );
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('.'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();

      final controller = tester.widget<TextField>(find.byType(TextField)).controller!;
      expect(controller.text, '1.5');
      expect(find.text('đ'), findsNothing);
    });
  });
}
