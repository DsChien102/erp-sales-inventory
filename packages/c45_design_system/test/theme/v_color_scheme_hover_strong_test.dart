import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  test('neutral150 khớp tokens.css', () {
    expect(VColors.neutral150, const Color(0xFFF1F3F5));
  });

  test('surfaceHoverStrong sáng = neutral150, tối = neutral500', () {
    expect(VColorScheme.light.surfaceHoverStrong, VColors.neutral150);
    expect(VColorScheme.dark.surfaceHoverStrong, VColors.neutral500);
  });

  test('lerp và copyWith giữ surfaceHoverStrong', () {
    expect(
      VColorScheme.light.lerp(VColorScheme.light, .5).surfaceHoverStrong,
      VColors.neutral150,
    );
    expect(
      VColorScheme.light.copyWith(surfaceHoverStrong: Colors.red).surfaceHoverStrong,
      Colors.red,
    );
  });

  testWidgets('VIcons.layers vẽ được', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(body: VIcon(icon: VIcons.layers)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(VIcon), findsOneWidget);
  });
}
