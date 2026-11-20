import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  test('VOverlayMenuShell uses bottom-weighted design-system shadow token', () {
    expect(VOverlayMenuShell.menuShadow, VShadows.e1);
    expect(VOverlayMenuShell.menuShadow.single.offset, const Offset(0, 2));
    expect(VOverlayMenuShell.menuShadow.single.blurRadius, 8);
  });

  testWidgets('VOverlayMenuShell.panel renders DecoratedBox with boxShadow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VOverlayMenuShell.panel(
            child: const SizedBox(height: 40, width: 200),
          ),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.boxShadow, VShadows.e1);
  });
}
