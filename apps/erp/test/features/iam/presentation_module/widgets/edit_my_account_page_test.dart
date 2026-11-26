import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
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
      expect(find.text('Chạm để thay hoặc xóa ảnh'), findsNothing);

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
      expect(find.text('Email đăng nhập'), findsOneWidget);
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

  group('10-8k EditMyAccountPage narrow & wide', () {
    testWidgets('invalid phone turns the field border danger', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const EditMyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '0912 34');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pump();

      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
      final phoneField = tester.widget<VField>(
        find.ancestor(
          of: find.byType(VPhoneField),
          matching: find.byType(VField),
        ),
      );
      expect(phoneField.invalid, isTrue);
    });

    testWidgets('typing a name keeps the phone error', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const EditMyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '0912 34');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pump();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'Hải');
      await tester.pump();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
    });

    testWidgets('avatar row is not tappable and has no chevron', (tester) async {
      for (final size in const [Size(390, 844), Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: const EditMyAccountPage(data: MyAccountUiModel.sample),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chạm để thay hoặc xóa ảnh'), findsNothing);
        expect(
          find.byWidgetPredicate((w) => w is VIcon && w.icon == VIcons.chevronRight),
          findsNothing,
        );
        final inkWells = find.ancestor(
          of: find.text('Ảnh đại diện'),
          matching: find.byType(InkWell),
        );
        for (final element in inkWells.evaluate()) {
          expect((element.widget as InkWell).onTap, isNull);
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('390: names share a row 3 : 2, email is a read-only row', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const EditMyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditAccountNarrow), findsOneWidget);
      expect(find.byType(EditAccountWide), findsNothing);
      final lastRect = tester.getRect(find.byType(TextField).at(0));
      final firstRect = tester.getRect(find.byType(TextField).at(1));
      expect(lastRect.left, lessThan(firstRect.left));
      expect(lastRect.width, greaterThan(firstRect.width));
      // 3 editable TextFields (lastName, firstName, phone); email is a read-only row with lock icon
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        find.byWidgetPredicate((w) => w is VIcon && w.icon == VIcons.lock),
        findsOneWidget,
      );
    });

    testWidgets('1280: one card in a 560 column, email is a disabled field', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const EditMyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditAccountWide), findsOneWidget);
      expect(find.byType(EditAccountNarrow), findsNothing);
      expect(find.byType(FlowCard), findsOneWidget);
      final cardWidth = tester.getSize(find.byType(FlowCard)).width;
      expect(cardWidth, lessThanOrEqualTo(560));
      expect(find.byType(TextField), findsNWidgets(4));
      expect(tester.widget<TextField>(find.byType(TextField).at(3)).enabled, isFalse);
    });

    testWidgets('bottom bar has a single top border', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const EditMyAccountPage(data: MyAccountUiModel.sample),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.bottomBar, isNotNull);
      final containersWithTopBorder = find.descendant(
        of: find.byWidget(scaffold.bottomBar!),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).border != null,
        ),
      );
      expect(containersWithTopBorder, findsNothing);
    });

    testWidgets('resizing keeps values and still asks before leaving', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      await tester.enterText(find.byType(TextField).at(1), 'Hải');
      await tester.pump();

      tester.view.physicalSize = const Size(700, 800);
      await tester.pumpAndSettle();

      expect(find.byType(EditAccountNarrow), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, 'Hải');

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    });

    testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            theme: VTheme.lightTheme,
            home: const EditMyAccountPage(data: MyAccountUiModel.sample),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
