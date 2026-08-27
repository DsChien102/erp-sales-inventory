import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VDivider', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('horizontal defaults to borderDefault and thickness 1', (tester) async {
      await tester.pumpWidget(wrap(const VDivider()));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, VColorScheme.light.borderDefault);
      final box = tester.renderObject<RenderBox>(find.byType(Container));
      expect(box.size.height, VBorders.thin);
    });

    testWidgets('vertical renders within bounded height', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            height: 40,
            child: Row(
              children: [
                Text('A'),
                VDivider(axis: Axis.vertical),
                Text('B'),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, VColorScheme.light.borderDefault);
      final box = tester.renderObject<RenderBox>(find.byType(Container));
      expect(box.size.width, VBorders.thin);
      expect(box.size.height, greaterThan(0));
    });

    testWidgets('explicit color and thickness override defaults', (tester) async {
      await tester.pumpWidget(
        wrap(
          VDivider(
            thickness: 3,
            color: VColorScheme.light.danger,
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, VColorScheme.light.danger);
      final box = tester.renderObject<RenderBox>(find.byType(Container));
      expect(box.size.height, 3);
    });
  });
}
