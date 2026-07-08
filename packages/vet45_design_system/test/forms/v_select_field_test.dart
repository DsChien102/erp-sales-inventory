import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VSelect', () {
    testWidgets('shows required label asterisk', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VSelect<String>(
              label: 'Trạng thái',
              value: null,
              isRequired: true,
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Active')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().startsWith('Trạng thái') &&
              widget.text.toPlainText().contains('*'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VSelect<String>(
              label: 'Trạng thái',
              value: null,
              isRequired: true,
              errorText: 'Lỗi từ parent',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Active')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Lỗi từ parent'), findsOneWidget);
      expect(find.text(VSelectValidator.defaultRequiredMessage), findsNothing);
    });

    testWidgets('shows helper text when no error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VSelect<String>(
              label: 'Trạng thái',
              value: 'a',
              helperText: 'Chọn trạng thái hiện tại',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Active')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Chọn trạng thái hiện tại'), findsOneWidget);
    });

    testWidgets('onChanged is called when item selected', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VSelect<String>(
              label: 'Trạng thái',
              value: null,
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Active')),
                DropdownMenuItem(value: 'b', child: Text('Inactive')),
              ],
              onChanged: (val) => selected = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(selected, 'a');
    });
  });
}
