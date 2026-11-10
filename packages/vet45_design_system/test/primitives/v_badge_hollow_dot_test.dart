import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VBadge hollowDot', () {
    final colors = VColorScheme.light;

    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('hollow_dot_draws_ring', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VBadge(
            label: 'Hết hàng',
            tone: VComponentTone.danger,
            showDot: true,
            hollowDot: true,
          ),
        ),
      );

      final containers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(VBadge),
              matching: find.byType(Container),
            ),
          )
          .toList();

      // First Container is the badge pill, second Container is the 8x8 dot
      expect(containers.length, greaterThanOrEqualTo(2));
      final dotContainer = containers[1];
      final size = tester.getSize(find.byWidget(dotContainer));
      expect(size, const Size(8, 8));

      final decoration = dotContainer.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.transparent);
      final border = decoration.border as Border?;
      expect(border, isNotNull);
      expect(border!.top.color, colors.danger);
      expect(border.top.width, 2.0);
    });
  });
}

