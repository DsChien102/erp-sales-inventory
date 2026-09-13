import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_input.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('VSearchBar composes VInput', (tester) async {
    await tester.pumpWidget(
      wrap(
        const VSearchBar(hintText: 'Search…'),
      ),
    );

    expect(find.byType(VSearchBar), findsOneWidget);
    expect(find.byType(VInput), findsOneWidget);
  });

  testWidgets('VSearchBar shows clear when text present and onClear set', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'abc');
    var cleared = 0;

    await tester.pumpWidget(
      wrap(
        VSearchBar(
          controller: controller,
          hintText: 'Search…',
          onClear: () => cleared++,
        ),
      ),
    );

    expect(find.byType(VIcon), findsWidgets);
    await tester.tap(find.byType(GestureDetector).last);
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(cleared, 1);
  });
}
