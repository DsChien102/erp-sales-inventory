import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VConfirmDialog', () {
    testWidgets('confirm_dialog_wraps_long_labels_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showVConfirmDialog(
                    context: context,
                    title: 'Bỏ thay đổi chưa lưu?',
                    message: 'Các giá trị vừa sửa sẽ không được lưu.',
                    cancelLabel: 'Ở lại chỉnh sửa tiếp',
                    actionLabel: 'Bỏ toàn bộ thay đổi chưa lưu',
                    isDestructive: true,
                    onAction: () => actionCalled = true,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should not overflow on 390px screen even with long button labels
      expect(tester.takeException(), isNull);
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      expect(find.text('Ở lại chỉnh sửa tiếp'), findsOneWidget);
      expect(find.text('Bỏ toàn bộ thay đổi chưa lưu'), findsOneWidget);

      await tester.tap(find.text('Bỏ toàn bộ thay đổi chưa lưu'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
    });
  });
}

