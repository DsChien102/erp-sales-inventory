import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../support/scripted_auth.dart';

void main() {
  testWidgets('no-organization page scrolls at large text on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = loginSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: NoOrganizationPage(session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException()?.toString(), isNot(contains('overflowed')));
    expect(find.text('Nhập mã lời mời'), findsOneWidget);
  });

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
