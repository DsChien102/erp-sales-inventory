import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> contentWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const key = Key('probe');
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: FlowColumn(children: [SizedBox(key: key, height: 10)]),
        ),
      ),
    );
    return tester.getSize(find.byKey(key)).width;
  }

  testWidgets('FlowColumn caps at 520 and keeps 16 gutters at 390', (tester) async {
    expect(await contentWidth(tester, 1280), 488);
    expect(await contentWidth(tester, 390), 358);
  });
}
