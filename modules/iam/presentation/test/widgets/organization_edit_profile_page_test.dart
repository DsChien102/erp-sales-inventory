import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('OrganizationEditProfilePage renders form fields and bottom action buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationEditProfilePage(),
      ),
    );

    // Title & top note
    expect(find.text('Chỉnh thông tin tổ chức'), findsWidgets);
    expect(find.text('Thông tin liên hệ này độc lập với hồ sơ pháp lý và chứng từ đã phát hành.'), findsOneWidget);

    // Form components
    expect(find.byType(VTextField), findsNWidgets(4));
    expect(find.byType(VDropdown<String>), findsNWidgets(2));

    // Input values
    expect(find.text('Thú y Minh Phát'), findsOneWidget);
    expect(find.text('Tên hiển thị.'), findsOneWidget);
    expect(find.text('0901 234 567'), findsOneWidget);
    expect(find.text('contact@minhphat.vn'), findsOneWidget);
    expect(find.text('125 Phạm Văn Thuận'), findsOneWidget);
    expect(find.text('Đồng Nai'), findsOneWidget);
    expect(find.text('Trấn Biên'), findsOneWidget);

    // Bottom action buttons
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);

    // Tap 'Lưu thay đổi'
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
  });
}
