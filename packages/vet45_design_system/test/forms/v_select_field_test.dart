import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
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

      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
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
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: VSelect<String>(
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
        ),
      );

      await tester.tap(find.byType(MenuAnchor));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();

      expect(selected, 'a');
    });

    testWidgets('menu shrinks to fit few items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: VSelect<String>(
                value: null,
                hintText: 'Chọn',
                items: const [
                  DropdownMenuItem(value: 'a', child: Text('Alpha')),
                  DropdownMenuItem(value: 'b', child: Text('Beta')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MenuAnchor));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MenuAnchor),
          matching: find.byType(ListView),
        ),
        findsNothing,
      );

      final metrics = VOverlayMenuLayout.panelMetrics(
        itemCount: 2,
        menuMaxHeight: 300,
        itemHeight: VCombobox.controlHeight,
        menuPadding: VSpacing.space2,
      );
      expect(metrics.needsScroll, isFalse);
      expect(metrics.shellHeight, VCombobox.controlHeight * 2 + VSpacing.space2 * 2);
    });

    testWidgets('unfocuses when tapping outside while menu is open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: VSelect<String>(
                value: null,
                hintText: 'Chọn',
                items: const [
                  DropdownMenuItem(value: 'a', child: Text('Alpha')),
                  DropdownMenuItem(value: 'b', child: Text('Beta')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MenuAnchor));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsNothing);
    });
  });
}
