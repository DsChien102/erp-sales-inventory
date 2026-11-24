import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('VGap', () {
    testWidgets('vertical sm uses VSpacing.sm height', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              SizedBox(height: 10, width: 10),
              VGap.sm(),
              SizedBox(height: 20, width: 20),
            ],
          ),
        ),
      );

      final gap = tester.widget<SizedBox>(find.byType(SizedBox).at(1));
      expect(gap.height, VSpacing.sm);
      expect(gap.width, isNull);
    });

    testWidgets('horizontal sm uses VSpacing.sm width', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [
              SizedBox(height: 10, width: 10),
              VGap.horizontalSm(),
              SizedBox(height: 20, width: 20),
            ],
          ),
        ),
      );

      final gap = tester.widget<SizedBox>(find.byType(SizedBox).at(1));
      expect(gap.width, VSpacing.sm);
      expect(gap.height, isNull);
    });
  });
}
