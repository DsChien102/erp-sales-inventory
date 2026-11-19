import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VBreakpoints', () {
    test('ofWidth thresholds', () {
      expect(VBreakpoints.ofWidth(599), VBreakpoint.mobile);
      expect(VBreakpoints.ofWidth(600), VBreakpoint.tablet);
      expect(VBreakpoints.ofWidth(1023), VBreakpoint.tablet);
      expect(VBreakpoints.ofWidth(1024), VBreakpoint.desktop);
    });

    test('isAtLeast / isAtMost', () {
      expect(VBreakpoint.desktop.isAtLeast(VBreakpoint.tablet), isTrue);
      expect(VBreakpoint.mobile.isAtLeast(VBreakpoint.tablet), isFalse);
      expect(VBreakpoint.mobile.isAtMost(VBreakpoint.tablet), isTrue);
      expect(VBreakpoint.desktop.isAtMost(VBreakpoint.tablet), isFalse);
    });
  });

  group('VPagePadding', () {
    testWidgets('defaults horizontal inset to screenMobile', (tester) async {
      late EdgeInsets resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VPagePadding(
              child: Builder(
                builder: (context) {
                  resolved = context.findAncestorWidgetOfExactType<Padding>()!.padding
                      as EdgeInsets;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved.left, VSpacing.screenMobile);
      expect(resolved.right, VSpacing.screenMobile);
    });
  });
}
