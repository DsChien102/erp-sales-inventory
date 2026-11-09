import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('VChip count', () {
    testWidgets('chip_count_renders_and_zero_is_muted', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Tất cả',
            count: 3,
          ),
        ),
      );

      expect(find.text(' 3'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return const VChip(
                label: 'Hỏng',
                count: 0,
              );
            },
          ),
        ),
      );

      final zeroFinder = find.text(' 0');
      expect(zeroFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(zeroFinder);
      final context = tester.element(zeroFinder);
      expect(textWidget.style?.color, context.vColors.textSecondary);
    });

    testWidgets('chip_without_count_unchanged', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Tất cả',
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
    });
  });
}
