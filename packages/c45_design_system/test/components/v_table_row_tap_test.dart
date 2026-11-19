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

  const headers = [
    VTableHeader(title: 'Mã'),
    VTableHeader(title: 'Tên'),
  ];

  final rows = [
    [const Text('01'), const Text('Hàng A')],
    [const Text('02'), const Text('Hàng B')],
  ];

  group('VTable onRowTap', () {
    testWidgets('table_row_tap_reports_index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        wrap(
          VTable(
            headers: headers,
            rows: rows,
            onRowTap: (index) => tappedIndex = index,
          ),
        ),
      );

      // Bấm ô cột 2 dòng 1 (index 1: 'Hàng B')
      await tester.tap(find.text('Hàng B'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 1);
    });

    testWidgets('table_first_cell_is_button_semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          VTable(
            headers: headers,
            rows: rows,
            onRowTap: (_) {},
          ),
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('01'),
        matching: find.byType(Semantics),
      );
      final hasButtonSemantics = cellFinder.evaluate().any((e) {
        final widget = e.widget as Semantics;
        return widget.properties.button == true;
      });
      expect(hasButtonSemantics, isTrue);
      handle.dispose();
    });

    testWidgets('table_without_onRowTap_unchanged', (tester) async {
      await tester.pumpWidget(
        wrap(
          VTable(
            headers: headers,
            rows: rows,
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });
}
