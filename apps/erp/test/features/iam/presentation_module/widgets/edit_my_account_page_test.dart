import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets(
    'wgt_e06_u02_fr01_01: EditMyAccountPage (TA-D-02) renders avatar card, input fields, read-only email, and dirty-checks save button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: EditMyAccountPage(data: MyAccountUiModel.sample),
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

  testWidgets('typing into first/last name clears error message', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditMyAccountPage(data: MyAccountUiModel.sample),
      ),
    );

    final lastNameField = find.byType(TextField).at(0);
    final firstNameField = find.byType(TextField).at(1);
    final saveButtonFinder = find.widgetWithText(VButton, 'Lưu thay đổi');

    // 1. Xoá trống ô "Tên" -> nút "Lưu thay đổi" vẫn bật vì hasChanges = true
    await tester.enterText(firstNameField, '');
    await tester.pump();
    expect(tester.widget<VButton>(saveButtonFinder).onPressed, isNotNull);

    // Bấm lưu -> "Vui lòng nhập tên" xuất hiện
    await tester.tap(saveButtonFinder);
    await tester.pump();
    expect(find.text('Vui lòng nhập tên'), findsOneWidget);

    // Gõ "A" vào ô Tên -> chữ lỗi biến mất
    await tester.enterText(firstNameField, 'A');
    await tester.pump();
    expect(find.text('Vui lòng nhập tên'), findsNothing);

    // 2. Tương tự với ô "Họ và tên đệm"
    await tester.enterText(lastNameField, '');
    await tester.pump();
    expect(tester.widget<VButton>(saveButtonFinder).onPressed, isNotNull);

    await tester.tap(saveButtonFinder);
    await tester.pump();
    expect(find.text('Vui lòng nhập họ và tên đệm'), findsOneWidget);

    await tester.enterText(lastNameField, 'Trần');
    await tester.pump();
    expect(find.text('Vui lòng nhập họ và tên đệm'), findsNothing);
  });

  group('PopScope discard confirmation in EditMyAccountPage', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditMyAccountPage(data: MyAccountUiModel.sample),
                  ),
                ),
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
    }

    testWidgets('unmodified form pops directly on back without dialog', (tester) async {
      await pumpPage(tester);
      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh sửa thông tin'), findsNothing);
    });

    testWidgets('modified form asks confirmation on back, can keep editing or discard', (tester) async {
      await pumpPage(tester);

      final firstNameField = find.byType(TextField).at(1);
      await tester.enterText(firstNameField, 'Nguyen Van Moi');
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      // Tap 'Tiếp tục sửa'
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsNothing);
      expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);
      expect(find.text('Nguyen Van Moi'), findsOneWidget);

      // Tap back button again and discard
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa thông tin'), findsNothing);
    });

    testWidgets('modified form asks confirmation on cancel button', (tester) async {
      await pumpPage(tester);

      final firstNameField = find.byType(TextField).at(1);
      await tester.enterText(firstNameField, 'Nguyen Van Moi');
      await tester.pumpAndSettle();

      // Tap 'Hủy' button
      await tester.tap(find.widgetWithText(VButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);

      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa thông tin'), findsNothing);
    });
  });
}
