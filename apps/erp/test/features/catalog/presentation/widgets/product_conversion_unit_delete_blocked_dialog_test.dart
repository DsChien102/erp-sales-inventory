import 'package:erp/features/catalog/presentation/widgets/product_conversion_unit_delete_blocked_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('t93_sp09_delete_blocked_shows_deactivate_button', (tester) async {
    var deactivated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductConversionUnitDeleteBlockedDialog(
            message: 'Đơn vị đã phát sinh giao dịch hoặc ràng buộc tồn kho.',
            onDeactivate: () {
              deactivated = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Đơn vị đã phát sinh giao dịch hoặc ràng buộc tồn kho.'),
      findsOneWidget,
    );
    expect(find.text('Đóng'), findsOneWidget);

    final deactivateButtonFinder = find.byKey(
      const Key('btn_suggest_deactivate_conversion_unit'),
    );
    expect(deactivateButtonFinder, findsOneWidget);
    expect(find.text('Tắt đơn vị'), findsOneWidget);

    await tester.tap(deactivateButtonFinder);
    await tester.pumpAndSettle();

    expect(deactivated, isTrue);
  });
}

