import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  test('phone validator checks characters before counting digits', () {
    for (final value in ['012345678', '01234567890', '0988 123 456']) {
      expect(VPhoneValidator.validate(value, isRequired: true), isNull);
    }
    for (final value in [
      '',
      '   ',
      '01234567',
      '012345678901',
      '0988abc123456',
      '+84988123456',
      '0988-123456',
      '0988123456\n',
    ]) {
      expect(VPhoneValidator.validate(value, isRequired: true), isNotNull);
    }
    expect(VPhoneValidator.validate('   '), isNull);
  });

  testWidgets('rejects invalid paste and preserves selection and leading zero', (tester) async {
    final controller = TextEditingController(text: '0988 123 456');
    final changes = <String>[];
    await tester.pumpWidget(_host(VPhoneField(controller: controller, onChanged: changes.add)));
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection.collapsed(offset: 4);
    final before = controller.value;
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '0988abc 123 456',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    expect(controller.value, before);
    expect(changes, isEmpty);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '09880 123 456',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(controller.text, '09880 123 456');
    expect(changes, ['09880 123 456']);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('debounces validation and clears errors after correction', (tester) async {
    await tester.pumpWidget(_host(const VPhoneField(isRequired: true)));
    await tester.enterText(find.byType(TextField), '098');
    expect(find.byType(VFieldError), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VFieldError), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0988123456');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VFieldError), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
  });

  testWidgets('validates controller changes and detaches replaced controller', (tester) async {
    final first = TextEditingController();
    final second = TextEditingController(text: '0988123456');
    await tester.pumpWidget(_host(VPhoneField(controller: first)));
    first.text = '0988abc123456';
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VFieldError), findsOneWidget);
    await tester.pumpWidget(_host(VPhoneField(controller: second)));
    expect(find.byType(VFieldError), findsNothing);
    first.text = 'abc';
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VFieldError), findsNothing);
    second.clear();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VFieldError), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    second.dispose();
  });

  testWidgets('external error takes precedence and disabled field cannot focus', (tester) async {
    final focus = FocusNode();
    await tester.pumpWidget(
      _host(
        VPhoneField(
          enabled: false,
          focusNode: focus,
          errorText: 'Server error',
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    expect(focus.hasFocus, isFalse);
    expect(find.text('Server error'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    focus.dispose();
  });
}

Widget _host(Widget child) => MaterialApp(
  theme: VTheme.lightTheme,
  home: Scaffold(body: child),
);
