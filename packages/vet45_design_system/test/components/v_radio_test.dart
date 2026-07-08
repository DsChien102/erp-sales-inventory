import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VRadio', () {
    testWidgets('tap label selects radio', (tester) async {
      String? selected = 'a';

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: RadioGroup<String>(
              groupValue: selected,
              onChanged: (val) => selected = val,
              child: Column(
                children: [
                  VRadio<String>(
                    value: 'a',
                    onChanged: null,
                    label: 'Option A',
                  ),
                  VRadio<String>(
                    value: 'b',
                    onChanged: null,
                    label: 'Option B',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(selected, 'b');
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: RadioGroup<String>(
              groupValue: 'a',
              onChanged: (_) {},
              child: VRadio<String>(
                value: 'a',
                onChanged: null,
                label: 'Option A',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Radio<String>), findsOneWidget);
    });
  });
}
