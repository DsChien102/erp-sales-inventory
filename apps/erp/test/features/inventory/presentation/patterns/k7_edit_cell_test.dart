import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('K7EditCell', () {
    testWidgets('shows_unit_suffix', (tester) async {
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '25',
            onChanged: (_) {},
            unit: 'hộp',
            semanticLabel: 'Ngưỡng cảnh báo',
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget);
      expect(find.text('hộp'), findsOneWidget);
    });

    testWidgets('shows_error_below_and_red_border', (tester) async {
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '5',
            onChanged: (_) {},
            errorText: 'Mục tiêu phải lớn hơn hoặc bằng ngưỡng.',
            semanticLabel: 'Mức tồn mục tiêu',
          ),
        ),
      );

      expect(
        find.text('Mục tiêu phải lớn hơn hoặc bằng ngưỡng.'),
        findsOneWidget,
      );

      final boxContainer = tester.widget<Container>(
        find.byKey(const Key('k7_edit_cell_box')),
      );
      final decoration = boxContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, const Color(0xFFB53232));
    });

    testWidgets('disabled_uses_subtle_background', (tester) async {
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '10',
            onChanged: (_) {},
            enabled: false,
            semanticLabel: 'Ngưỡng',
          ),
        ),
      );

      final boxContainer = tester.widget<Container>(
        find.byKey(const Key('k7_edit_cell_box')),
      );
      final decoration = boxContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFE5E8EB));
    });

    testWidgets('height_44_mobile_40_web', (tester) async {
      // Mobile 390
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '10',
            onChanged: (_) {},
            semanticLabel: 'Ngưỡng',
          ),
          size: const Size(390, 844),
        ),
      );

      final mobileBox = tester.widget<Container>(
        find.byKey(const Key('k7_edit_cell_box')),
      );
      expect(mobileBox.constraints?.minHeight, 44.0);

      // Web 1280
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '10',
            onChanged: (_) {},
            semanticLabel: 'Ngưỡng',
          ),
          size: const Size(1280, 800),
        ),
      );

      final webBox = tester.widget<Container>(
        find.byKey(const Key('k7_edit_cell_box')),
      );
      expect(webBox.constraints?.minHeight, 40.0);
    });

    testWidgets('semantics_label', (tester) async {
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '10',
            onChanged: (_) {},
            semanticLabel: 'Ngưỡng cảnh báo — Nobivac',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Nobivac'),
        findsOneWidget,
      );
    });

    testWidgets('no_inner_border', (tester) async {
      await tester.pumpWidget(
        buildApp(
          K7EditCell(
            value: '10',
            onChanged: (_) {},
            semanticLabel: 'Ngưỡng',
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final dec = textField.decoration;
      expect(dec?.border, InputBorder.none);
      expect(dec?.enabledBorder, InputBorder.none);
      expect(dec?.focusedBorder, InputBorder.none);
      expect(dec?.disabledBorder, InputBorder.none);
    });
  });
}

