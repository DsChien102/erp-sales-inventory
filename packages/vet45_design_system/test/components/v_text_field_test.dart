import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_input.dart';
import 'package:vet45_design_system/src/components/v_text_field_focus_ring.dart';

void main() {
  group('VTextField + VInput', () {
    testWidgets('composes VInput inside VTextFieldFocusRing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VTextField(hintText: 'Nhập'),
          ),
        ),
      );

      expect(find.byType(VInput), findsOneWidget);
      expect(find.byType(VTextFieldFocusRing), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders suffixText outside editable text', (tester) async {
      final controller = TextEditingController(text: '1000');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VTextField(
              controller: controller,
              suffixText: 'đ',
            ),
          ),
        ),
      );

      expect(find.text('1000'), findsOneWidget);
      expect(find.text('đ'), findsOneWidget);
      expect(controller.text, '1000');
    });

    testWidgets('VInput accepts prefix and suffix widgets inside padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VInput(
              hintText: 'x',
              prefix: Icon(Icons.search, size: 16),
              suffix: Text('kg'),
            ),
          ),
        ),
      );

      final input = tester.widget<VInput>(find.byType(VInput));
      expect(input.prefix, isA<Icon>());
      expect(input.suffix, isA<Text>());
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });
  });
}
