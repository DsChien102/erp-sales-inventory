import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('OrganizationProfilePage renders top card, organization details, legal notice, and bottom action bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationProfilePage(),
      ),
    );

    // Header & title
    expect(find.text('Hồ sơ tổ chức'), findsWidgets);
    expect(find.text('Thú y Minh Phát'), findsWidgets);
    expect(find.text('Hoạt động'), findsOneWidget);

    // Section 1: Thông tin tổ chức
    expect(find.text('Thông tin tổ chức'), findsOneWidget);
    expect(find.text('Tên hiển thị'), findsOneWidget);
    expect(find.text('Điện thoại'), findsOneWidget);
    expect(find.text('0901 234 567'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('contact@minhphat.vn'), findsOneWidget);
    expect(find.text('Địa chỉ'), findsOneWidget);
    expect(find.text('Biên Hòa, Đồng Nai'), findsOneWidget);

    // Section 2: Hồ sơ pháp lý
    expect(find.text('Hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Chưa có hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Có thể bổ sung sau. Một số tính năng pháp lý chưa sử dụng được.'), findsOneWidget);

    // Bottom Action Bar
    expect(find.text('Thao tác'), findsOneWidget);

    // Tap 'Thao tác' button to open bottom sheet
    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    // Verify Bottom Sheet opens (TA-O-01)
    expect(find.text('Thao tác hồ sơ'), findsOneWidget);
    expect(find.text('Chỉnh sửa thông tin tổ chức'), findsOneWidget);
    expect(find.text('Cập nhật thông tin liên hệ và địa chỉ'), findsOneWidget);
    expect(find.text('Thêm hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Bổ sung thông tin pháp lý'), findsOneWidget);
  });
}
