import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VAppBar', () {
    Future<void> pumpPushed(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(appBar: VAppBar(title: 'Chi tiết')),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
    }

    testWidgets('back button is named "Quay lại"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPushed(tester);

      expect(find.byTooltip('Quay lại'), findsOneWidget);
      final node = tester.getSemantics(find.byTooltip('Quay lại'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.tooltip.isNotEmpty || node.label.contains('Quay lại'), isTrue);
      handle.dispose();
    });

    testWidgets('back button pops the route', (tester) async {
      await pumpPushed(tester);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết'), findsNothing);
    });

    testWidgets('no back button on the root route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(appBar: VAppBar(title: 'Gốc')),
        ),
      );
      expect(find.byTooltip('Quay lại'), findsNothing);
    });
  });
}
