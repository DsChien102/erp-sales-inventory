import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  testWidgets('initial value sync preserves editing selection on state echo', (tester) async {
    var value = '0901 234 567';
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return VPhoneField(
          initialValue: value,
          validateOnChanged: false,
          onChanged: (next) => setState(() => value = next),
        );
      })),
    ));
    final field = find.byType(TextField);
    final controller = tester.widget<TextField>(field).controller!;
    expect(controller.text, '0901 234 567');
    await tester.tap(field);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '09012 234 567', selection: TextSelection.collapsed(offset: 5),
    ));
    await tester.pump();
    expect(value, '09012 234 567');
    expect(controller.selection.baseOffset, 5);
    update(() => value = '028 3822 1122');
    await tester.pump();
    expect(controller.text, '028 3822 1122');
    update(() => value = '+84 901234567');
    await tester.pump(const Duration(seconds: 1));
    expect(controller.text, '+84 901234567');
    expect(find.byType(VFieldError), findsNothing);
    expect(VPhoneValidator.validate(controller.text), isNotNull);
    update(() => value = '');
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  test('controller and initialValue cannot both supply text', () {
    final controller = TextEditingController();
    expect(() => VPhoneField(controller: controller, initialValue: '0901234567'), throwsAssertionError);
    controller.dispose();
  });

  testWidgets('switching controller ownership preserves or initializes text', (tester) async {
    final external = TextEditingController(text: '0901234567');
    Future<void> show(VPhoneField field) => tester.pumpWidget(MaterialApp(
      theme: VTheme.lightTheme, home: Scaffold(body: field),
    ));
    await show(VPhoneField(controller: external, validateOnChanged: false));
    await show(const VPhoneField(initialValue: '02838221122', validateOnChanged: false));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '02838221122');
    external.text = '0912345678';
    await show(VPhoneField(controller: external, validateOnChanged: false));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '0912345678');
    await show(const VPhoneField(validateOnChanged: false));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '0912345678');
    await tester.pumpWidget(const SizedBox.shrink());
    external.dispose();
  });
}
