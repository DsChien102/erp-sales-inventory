import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets(
    'EditMyAccountPage (TA-D-02) renders avatar card, input fields, read-only email, and dirty-checks save button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EditMyAccountPage(),
        ),
      );

      // Title
      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);

      // Avatar Card
      expect(find.text('Ảnh đại diện'), findsOneWidget);
      expect(find.text('Chạm để thay hoặc xóa ảnh'), findsOneWidget);

      // Fields
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Họ và tên đệm'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Tên')),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Số điện thoại'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Email đăng nhập'),
        ),
        findsOneWidget,
      );
      expect(find.text('minh@gmail.com'), findsOneWidget);

      // Buttons
      expect(find.text('Hủy'), findsOneWidget);
      final saveButtonFinder = find.widgetWithText(VButton, 'Lưu thay đổi');
      expect(saveButtonFinder, findsOneWidget);

      // Verify Save button is initially disabled (no changes made)
      final saveButtonInitial = tester.widget<VButton>(saveButtonFinder);
      expect(saveButtonInitial.onPressed, isNull);

      // Enter new text in first name field
      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'Nguyễn Thanh');
      await tester.pump();

      // Verify Save button is now enabled
      final saveButtonChanged = tester.widget<VButton>(saveButtonFinder);
      expect(saveButtonChanged.onPressed, isNotNull);
    },
  );
}
