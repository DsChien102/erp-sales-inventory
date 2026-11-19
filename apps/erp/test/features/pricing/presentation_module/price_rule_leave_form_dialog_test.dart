import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/pricing/presentation.dart';

void main() {
  testWidgets('showPriceRuleLeaveFormDialog uses VBottomSheet copy',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: VButton(
              label: 'Open',
              onPressed: () => showPriceRuleLeaveFormDialog(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Rời khỏi màn hình?'), findsOneWidget);
    expect(find.text('Những thay đổi chưa lưu sẽ bị mất.'), findsOneWidget);
    expect(find.text('Ở lại chỉnh sửa'), findsOneWidget);
    expect(find.text('Rời khỏi'), findsOneWidget);
    expect(find.byType(VBottomSheet), findsOneWidget);
  });
}
