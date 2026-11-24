import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('VKeyValueRow & VKeyValueGroup', () {
    testWidgets('key_value_long_value_wraps_no_overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: VKeyValueGroup(
                rows: [
                  VKeyValueRow(
                    label: 'Tồn kho đã đổi',
                    value: 'Nobivac DHPPi 120 hộp → 122 hộp',
                    mono: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Nobivac DHPPi 120 hộp → 122 hộp'), findsOneWidget);
    });

    testWidgets('key_value_mono_uses_mono_style', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VKeyValueRow(
            label: 'Tổng tiền',
            value: '1.200.000 đ',
            mono: true,
          ),
        ),
      );

      expect(find.text('Tổng tiền'), findsOneWidget);
      final valueFinder = find.text('1.200.000 đ');
      expect(valueFinder, findsOneWidget);

      final text = tester.widget<Text>(valueFinder);
      expect(text.style?.fontFamily, VTypography.monoNumeric.fontFamily);
    });

    testWidgets('group_renders_title_and_rows', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VKeyValueGroup(
            title: 'Chi tiết phiếu',
            rows: [
              VKeyValueRow(label: 'Mã phiếu', value: 'PN-01'),
              VKeyValueRow(label: 'Người nhận', value: 'Minh Dũng'),
            ],
          ),
        ),
      );

      expect(find.text('Chi tiết phiếu'), findsOneWidget);
      expect(find.text('Mã phiếu'), findsOneWidget);
      expect(find.text('PN-01'), findsOneWidget);
      expect(find.text('Người nhận'), findsOneWidget);
      expect(find.text('Minh Dũng'), findsOneWidget);
    });
  });
}
