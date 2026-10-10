import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/session/fake_session_repository.dart';
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

  testWidgets('a platform admin without an organization can open platform admin', (tester) async {
    final session = loginSession(
      repository: FakeSessionRepository(noTenants: true, platformAdmin: true),
    );
    addTearDown(session.close);
    await session.bootstrap();
    expect(session.state.hasNoOrganization, isTrue);
    expect(session.state.isPlatformAdmin, isTrue);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => NoOrganizationPage(session: session)),
        GoRoute(
          path: '/more/platform/organizations',
          builder: (_, _) => const Scaffold(body: Text('PLATFORM ORGS')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router));
    await tester.pumpAndSettle();

    // Giữa "Nhập mã lời mời" và "Đăng xuất" (A2).
    final invite = tester.getTopLeft(find.byKey(const Key('no_organization_invite'))).dy;
    final platform = tester.getTopLeft(find.byKey(const Key('no_organization_platform_admin'))).dy;
    final signOut = tester.getTopLeft(find.byKey(const Key('no_organization_sign_out'))).dy;
    expect(invite, lessThan(platform));
    expect(platform, lessThan(signOut));

    await tester.tap(find.text('Quản trị nền tảng'));
    await tester.pumpAndSettle();

    expect(find.text('PLATFORM ORGS'), findsOneWidget);
  });
}
