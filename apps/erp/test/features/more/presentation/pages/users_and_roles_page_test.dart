import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';

void main() {
  testWidgets('UsersAndRolesPage renders header, warning banner, and 5 menu cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: UsersAndRolesPage(),
      ),
    );

    // Verify app bar title
    expect(find.text('Người dùng & vai trò'), findsWidgets);

    // Verify warning banner
    expect(find.text('Cần hoàn tất'), findsOneWidget);
    expect(find.text('Tổ chức chưa hoàn tất thiết lập'), findsOneWidget);
    expect(find.text('Còn 1 điều kiện bắt buộc trước khi có thể bắt đầu vận hành.'), findsOneWidget);
    expect(find.text('Xem và hoàn tất'), findsOneWidget);

    // Verify 5 option cards
    expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
    expect(find.text('Thông tin liên hệ và địa chỉ tổ chức'), findsOneWidget);

    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Thành viên, lời mời và quyền truy cập'), findsOneWidget);

    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Phạm vi thao tác theo từng vai trò'), findsOneWidget);

    expect(find.text('Quyền sở hữu'), findsOneWidget);
    expect(find.text('Chủ tổ chức và chuyển quyền sở hữu'), findsOneWidget);

    expect(find.text('Lịch sử quản trị'), findsOneWidget);
    expect(find.text('Theo dõi thay đổi người dùng và quyền'), findsOneWidget);
  });
}
