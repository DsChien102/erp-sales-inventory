import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_input.dart';

void main() {
  testWidgets('VInput locked height matches VButton medium via VDensity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              VInput(hintText: 'Field'),
              VButton(label: 'Action', onPressed: null),
            ],
          ),
        ),
      ),
    );

    final expected = VDensity.comfortable.controlHeightMedium;
    final inputBox = tester.getSize(find.byType(VInput));
    final button = tester.widget<TextButton>(find.byType(TextButton));
    final buttonHeight = button.style?.fixedSize?.resolve({})?.height;

    expect(inputBox.height, expected);
    expect(buttonHeight, expected);
  });
}
