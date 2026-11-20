import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(400, 800)}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    );
  }

  group('VResponsiveValue', () {
    test('cascades desktop → tablet → mobile', () {
      const value = VResponsiveValue(
        mobile: 1,
        tablet: 2,
      );
      expect(value.resolve(VBreakpoint.mobile), 1);
      expect(value.resolve(VBreakpoint.tablet), 2);
      expect(value.resolve(VBreakpoint.desktop), 2);
    });

    test('uses desktop when provided', () {
      const value = VResponsiveValue(
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );
      expect(value.resolve(VBreakpoint.desktop), 3);
    });
  });

  group('VResponsive', () {
    testWidgets('reports mobile for narrow constraints', (tester) async {
      VBreakpoint? seen;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            child: VResponsive(
              builder: (context, breakpoint) {
                seen = breakpoint;
                return Text(breakpoint.name);
              },
            ),
          ),
        ),
      );
      expect(seen, VBreakpoint.mobile);
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('reports desktop for wide constraints', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      VBreakpoint? seen;
      await tester.pumpWidget(
        wrap(
          size: const Size(1200, 800),
          SizedBox(
            width: 1200,
            child: VResponsive(
              builder: (context, breakpoint) {
                seen = breakpoint;
                return Text(breakpoint.name);
              },
            ),
          ),
        ),
      );
      expect(seen, VBreakpoint.desktop);
    });
  });

  group('VResponsiveVisibility', () {
    testWidgets('hides when breakpoint does not match', (tester) async {
      await tester.pumpWidget(
        wrap(
          size: const Size(400, 800),
          const VResponsiveVisibility(
            visibleOn: VBreakpoint.desktop,
            child: Text('desktop-only'),
          ),
        ),
      );
      expect(find.text('desktop-only'), findsNothing);
    });

    testWidgets('shows when visibleFrom matches', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          size: const Size(800, 800),
          const SizedBox(
            width: 800,
            child: VResponsiveVisibility(
              visibleFrom: VBreakpoint.tablet,
              child: Text('from-tablet'),
            ),
          ),
        ),
      );
      expect(find.text('from-tablet'), findsOneWidget);
    });
  });

  group('VResponsiveGrid', () {
    testWidgets('uses one column on mobile', (tester) async {
      await tester.pumpWidget(
        wrap(
          size: const Size(400, 800),
          SizedBox(
            width: 400,
            child: VResponsiveGrid(
              children: [
                for (var i = 0; i < 2; i++)
                  const SizedBox(height: 40, child: ColoredBox(color: Colors.blue)),
              ],
            ),
          ),
        ),
      );

      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((s) => s.width != null && s.width! > 100)
          .toList();
      expect(sizedBoxes, isNotEmpty);
      expect(sizedBoxes.first.width, closeTo(400, 1));
    });
  });

  group('VContentWidth', () {
    testWidgets('applies tablet max width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          size: const Size(900, 800),
          const SizedBox(
            width: 900,
            child: VContentWidth(
              child: ColoredBox(color: Colors.red, child: SizedBox(height: 20)),
            ),
          ),
        ),
      );

      final constrained = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(VContentWidth),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrained.constraints.maxWidth, 840);
    });
  });
}