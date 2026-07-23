import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('OrganizationInviteMemberPage renders form fields with empty email initially and handles validation (TA-D-03)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OrganizationInviteMemberPage(),
      ),
    );

    // Title & top note
    expect(find.text('Mời thành viên'), findsWidgets);
    expect(find.text('Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.'), findsOneWidget);

    // Form fields
    expect(find.byType(VTextField), findsOneWidget);
    expect(find.byType(VDropdown<String>), findsOneWidget);

    // Initial email is empty, hint text is nhanvien@minhphat.vn
    expect(find.text('nhanvien@minhphat.vn'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Người nhận phải đăng nhập đúng email.'), findsOneWidget);
    expect(find.text('Vai trò có thể thay đổi sau khi tham gia.'), findsOneWidget);

    // Bottom action buttons
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Gửi lời mời'), findsOneWidget);

    // Tap 'Gửi lời mời' without entering email -> validation error shows
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);

    // Enter email and tap 'Gửi lời mời' -> success navigating to detail page & VToast
    await tester.enterText(find.byType(TextField), 'testuser@minhphat.vn');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết lời mời'), findsWidgets);
    expect(find.text('testuser@minhphat.vn'), findsOneWidget);
    expect(find.text('Đã gửi lời mời thành công.'), findsOneWidget);
  });
}
