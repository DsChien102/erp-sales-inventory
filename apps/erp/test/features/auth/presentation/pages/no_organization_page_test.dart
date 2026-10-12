import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../support/scripted_auth.dart';

void main() {
  testWidgets('no-organization page has no create-organization action', (tester) async {
    final session = loginSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: NoOrganizationPage(session: session),
      ),
    );

    expect(find.text('Bạn chưa thuộc tổ chức nào'), findsOneWidget);
    expect(find.text('Nhập mã lời mời'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.textContaining('Tạo tổ chức'), findsNothing);
    expect(find.textContaining('Đăng ký cửa hàng'), findsNothing);
    expect(find.text('Quản trị nền tảng'), findsNothing);
  });
}
