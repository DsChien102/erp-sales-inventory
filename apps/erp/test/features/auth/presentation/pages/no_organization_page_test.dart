import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import '../../../receivable/presentation/receivable_test_harness.dart' show loadInterFont;
import '../../support/scripted_auth.dart';
import '../../support/test_router.dart';

void main() {
  setUpAll(loadInterFont);

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

  Future<TestRouter> pumpNoOrg(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = loginSession();
    addTearDown(session.close);
    final harness = TestRouter(
      initial: '/no-organization',
      pages: {'/no-organization': NoOrganizationPage(session: session)},
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('invite goes to invitation', (tester) async {
    await pumpNoOrg(tester);
    await tester.tap(find.byKey(const Key('no_organization_invite')));
    await tester.pumpAndSettle();
    expect(find.text('INVITATION_PAGE'), findsOneWidget);
  });

  testWidgets('sign out goes to login', (tester) async {
    await pumpNoOrg(tester);
    await tester.tap(find.byKey(const Key('no_organization_sign_out')));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN_PAGE'), findsOneWidget);
  });

  testWidgets('390: actions at the bottom, sign out is a link', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: NoOrganizationPage(session: session),
      ),
    );
    await tester.pumpAndSettle();

    final invite = find.byKey(const Key('no_organization_invite'));
    final signOut = find.byKey(const Key('no_organization_sign_out'));
    expect(tester.getSize(invite).width, 358);
    expect(tester.widget<VButton>(signOut).variant, VButtonVariant.link);
    expect(tester.getRect(signOut).bottom, lessThanOrEqualTo(844 - 34));
    expect(tester.getRect(signOut).bottom, greaterThan(844 - 34 - 24));
  });

  testWidgets('375x667 without a home bar keeps 16 under sign out', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: NoOrganizationPage(session: session),
      ),
    );
    await tester.pumpAndSettle();
    final out = tester.getRect(find.byKey(const Key('no_organization_sign_out')));
    expect(out.bottom, 667 - 16);
  });

  testWidgets('1280: card 528 wide, primary on the right of sign out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = loginSession();
    addTearDown(session.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: NoOrganizationPage(session: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(FlowCard)).width, 528);
    final invite = tester.getRect(find.byKey(const Key('no_organization_invite')));
    final signOut = tester.getRect(find.byKey(const Key('no_organization_sign_out')));
    expect(invite.left, greaterThan(signOut.right));
  });
}
