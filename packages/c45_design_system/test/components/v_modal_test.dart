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

    Future<void> openDialog(WidgetTester tester, double w) async {
      tester.view.physicalSize = Size(w, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showVConfirmDialog(
                  context: context,
                  title: 'Bỏ thay đổi chưa lưu?',
                  message: 'Các giá trị vừa sửa sẽ không được lưu.',
                  cancelLabel: 'Ở lại',
                  actionLabel: 'Bỏ thay đổi',
                  onAction: () {},
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('390: width 310, padding 20', (tester) async {
      await openDialog(tester, 390);
      final body = find.byKey(const Key('v-confirm-dialog-body'));
      expect(tester.getSize(body).width, 310);
      expect(
        tester.getTopLeft(find.text('Bỏ thay đổi chưa lưu?')).dx - tester.getTopLeft(body).dx,
        20,
      );
    });

    testWidgets('1280: width 440, padding 24', (tester) async {
      await openDialog(tester, 1280);
      final body = find.byKey(const Key('v-confirm-dialog-body'));
      expect(tester.getSize(body).width, 440);
      expect(tester.getCenter(body).dx, 640);
      expect(
        tester.getTopLeft(find.text('Bỏ thay đổi chưa lưu?')).dx - tester.getTopLeft(body).dx,
        24,
      );
    });
  });
}

