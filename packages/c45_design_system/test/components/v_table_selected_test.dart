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

  List<List<Widget>> rows() => [
        [const Text('01'), const Text('Hàng A')],
        [const Text('02'), const Text('Hàng B')],
      ];

  List<TableRow> tableRows(WidgetTester tester) =>
      tester.widget<Table>(find.byType(Table).last).children;

  group('VTable selectedRowIndex', () {
    testWidgets('selected_row_background', (tester) async {
      await tester.pumpWidget(
        wrap(VTable(headers: headers, rows: rows(), selectedRowIndex: 1)),
      );

      final colors = VTheme.lightTheme.extension<VColorScheme>()!;
      final body = tableRows(tester);
      final selected = body.last.decoration as BoxDecoration?;
      expect(selected?.color, colors.surfaceBrand);
      expect(body[body.length - 2].decoration, isNull);
    });

    testWidgets('no_selection_by_default', (tester) async {
      await tester.pumpWidget(wrap(VTable(headers: headers, rows: rows())));

      final body = tableRows(tester);
      expect(body.last.decoration, isNull);
      expect(body[body.length - 2].decoration, isNull);
    });

    testWidgets('selected_semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          VTable(
            headers: headers,
            rows: rows(),
            selectedRowIndex: 0,
            onRowTap: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('01')),
        isSemantics(isSelected: true, isButton: true, label: '01'),
      );
      expect(
        tester.getSemantics(find.text('02')),
        isNot(isSemantics(isSelected: true)),
      );
      handle.dispose();
    });
  });
}
