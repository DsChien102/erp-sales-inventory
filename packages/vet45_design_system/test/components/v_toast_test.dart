import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VToast', () {
    Future<void> pumpToast(WidgetTester tester, VToastType type) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: VButton(
                  label: 'Show toast',
                  onPressed: () => VToast.show(
                    context,
                    title: '',
                    message: 'Toast message',
                    type: type,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('danger toast uses circleX icon', (tester) async {
      await pumpToast(tester, VToastType.danger);

      final iconBox = tester.widget<VIconBox>(find.byType(VIconBox));
      expect(iconBox.icon, VIcons.error);
    });

    testWidgets('success toast still uses success icon', (tester) async {
      await pumpToast(tester, VToastType.success);

      final iconBox = tester.widget<VIconBox>(find.byType(VIconBox));
      expect(iconBox.icon, VIcons.success);
    });
  });
}
