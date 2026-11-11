import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(800, 600)}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('VSummaryStrip', () {
    testWidgets('summary_strip_renders_items_mono', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VSummaryStrip(
            items: [
              VSummaryItem('Tổng tiền', '1.000.000 đ'),
              VSummaryItem('Số dòng', '3'),
            ],
          ),
        ),
      );

      expect(find.text('Tổng tiền'), findsOneWidget);
      expect(find.text('1.000.000 đ'), findsOneWidget);
      expect(find.text('Số dòng'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      final valText = tester.widget<Text>(find.text('1.000.000 đ'));
      expect(valText.style?.fontFamily?.contains('Mono'), isTrue);
    });

    testWidgets('summary_strip_wraps_2x2_narrow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const VSummaryStrip(
            items: [
              VSummaryItem('Mục 1', '10'),
              VSummaryItem('Mục 2', '20'),
              VSummaryItem('Mục 3', '30'),
              VSummaryItem('Mục 4', '40'),
            ],
          ),
          size: const Size(390, 844),
        ),
      );

      expect(find.text('Mục 1'), findsOneWidget);
      expect(find.text('Mục 2'), findsOneWidget);
      expect(find.text('Mục 3'), findsOneWidget);
      expect(find.text('Mục 4'), findsOneWidget);

      // In 2x2 grid on narrow screen, first two items are on row 1, last two on row 2
      final pos1 = tester.getTopLeft(find.text('Mục 1'));
      final pos2 = tester.getTopLeft(find.text('Mục 2'));
      final pos3 = tester.getTopLeft(find.text('Mục 3'));

      expect(pos1.dy, closeTo(pos2.dy, 1.0));
      expect(pos3.dy, greaterThan(pos1.dy));
    });
  });
}

