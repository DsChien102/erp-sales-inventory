import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/receivable/presentation/receivable_test_harness.dart';

String _goldenPath(String name) =>
    '${repoRoot()}/docs/refactor/plans/P10/img/10-8d/$name.png';

Future<void> _pumpFoundation(
  WidgetTester tester, {
  required double width,
  required double column,
  required VStepProgressVariant variant,
  required int emptyLength,
  required int partialLength,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final key = GlobalKey();
  final split = width < 840;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: column,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VStepProgress(
                      titles: const ['Tài khoản', 'Cửa hàng', 'Xác minh email'],
                      currentIndex: 0,
                      variant: variant,
                    ),
                    const SizedBox(height: 24),
                    VVerificationCodeField(
                      length: emptyLength,
                      layout: VVerificationCodeLayout.fill,
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    VField(
                      invalid: true,
                      child: VVerificationCodeField(
                        length: emptyLength,
                        layout: VVerificationCodeLayout.fill,
                      ),
                    ),
                    const SizedBox(height: 24),
                    VVerificationCodeField(
                      length: partialLength,
                      charset: VVerificationCodeCharset.alphanumeric,
                      layout: split
                          ? VVerificationCodeLayout.split4
                          : VVerificationCodeLayout.fill,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(1), '123456');
  await tester.enterText(fields.at(2), 'K7M2');
  await tester.tap(fields.at(0));
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(_goldenPath('flutter-foundation-${width.toInt()}')),
  );
}

void main() {
  setUpAll(loadInterFont);

  testWidgets('foundation 390', (tester) async {
    await _pumpFoundation(
      tester,
      width: 390,
      column: 358,
      variant: VStepProgressVariant.mobile,
      emptyLength: 6,
      partialLength: 8,
    );
  });

  testWidgets('foundation 1280', (tester) async {
    await _pumpFoundation(
      tester,
      width: 1280,
      column: 446,
      variant: VStepProgressVariant.standard,
      emptyLength: 6,
      partialLength: 8,
    );
  });
}
