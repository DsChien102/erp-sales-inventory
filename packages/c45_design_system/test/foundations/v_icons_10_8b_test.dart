import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 10-8b: icon nút nổi "Hỏi Mosaic Retail" và nút mở toàn màn hình.
void main() {
  test('messageCircle / maximize dùng glyph Lucide', () {
    expect(VIcons.messageCircle.value, const IconData(57622, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter'));
    expect(VIcons.maximize.value, const IconData(57619, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter'));
  });

  testWidgets('VIcons.messageCircle và VIcons.maximize vẽ được', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: Row(children: [VIcon(icon: VIcons.messageCircle), VIcon(icon: VIcons.maximize)]),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(VIcon), findsNWidgets(2));
  });
}
