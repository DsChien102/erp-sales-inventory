import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('OrganizationLegalProfileFormPage renders unauthorized empty view when hasPermission is false', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationLegalProfileFormPage(hasPermission: false),
      ),
    );

    expect(find.text('Không có quyền xem tổ chức'), findsOneWidget);
    expect(find.text('Liên hệ chủ cửa hàng để được cấp quyền quản lý tổ chức nền tảng.'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('OrganizationLegalProfileFormPage renders Add mode (TA-D-03) with disabled save button initially', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationLegalProfileFormPage(isEdit: false),
      ),
    );

    // Title & top note
    expect(find.text('Thêm hồ sơ pháp lý'), findsWidgets);
    expect(find.text('Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.'), findsOneWidget);

    // Form fields present
    expect(find.byType(VTextField), findsNWidgets(3));
    expect(find.byType(VDropdown<String>), findsNWidgets(3));

    // Save button initial state is disabled (onPressed is null)
    final saveButtonFinder = find.widgetWithText(VButton, 'Lưu hồ sơ');
    expect(saveButtonFinder, findsOneWidget);
    final saveButton = tester.widget<VButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('OrganizationLegalProfileFormPage renders Edit mode (TA-D-04) pre-filled and triggers duplicate tax code sheet (TA-O-02)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationLegalProfileFormPage(isEdit: true),
      ),
    );

    // Title
    expect(find.text('Chỉnh hồ sơ pháp lý'), findsWidgets);

    // Pre-filled values
    expect(find.text('Hộ kinh doanh'), findsOneWidget);
    expect(find.text('HKD Thú y Minh Phát'), findsOneWidget);
    expect(find.text('360123456789'), findsOneWidget);
    expect(find.text('125 Phạm Văn Thuận'), findsOneWidget);
    expect(find.text('Đồng Nai'), findsOneWidget);
    expect(find.text('Trấn Biên'), findsOneWidget);

    // Type in tax code field to trigger hasChanges
    await tester.enterText(find.byType(TextField).at(1), '360123456789999');
    await tester.pumpAndSettle();

    // Enable Save button, tap 'Lưu hồ sơ'
    final saveButtonFinder = find.widgetWithText(VButton, 'Lưu hồ sơ');
    final saveButton = tester.widget<VButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verify duplicate tax code warning bottom sheet opens (TA-O-02)
    expect(find.text('Mã số thuế đã được ghi nhận'), findsOneWidget);
    expect(find.text('Có thể tiếp tục lưu'), findsOneWidget);
    expect(find.text('Vẫn lưu'), findsOneWidget);
    expect(find.text('Kiểm tra lại'), findsOneWidget);
  });
}
