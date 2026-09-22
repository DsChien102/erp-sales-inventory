import 'package:admin/features/users/presentation/pages/platform_user_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';

/// wgt_e01_u02_fr01_01 — Platform user detail + lifecycle via IIamModule.
void main() {
  testWidgets('loads detail for known userId — wgt_e01_u02_fr01_01', (WidgetTester tester) async {
    final module = FakeIamModule(scenario: FakeIamScenario.userDetailOk);

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformUserDetailPage(userId: 'lan-le', iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lê Thị Lan'), findsWidgets);
    expect(find.text('lan@gmail.com'), findsOneWidget);
    expect(find.text('Tài khoản nền tảng'), findsNothing);
    expect(find.text('Thao tác'), findsOneWidget);
  });

  testWidgets(
    'pendingActivation user has no PA-O-02 activation invite action',
    (WidgetTester tester) async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.activationResendOk,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlatformUserDetailPage(userId: 'hoa-tran', iamModule: module),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gửi lại email kích hoạt'), findsNothing);
      expect(find.text('Thao tác'), findsNothing);
    },
  );

  testWidgets('shows not-found when user missing', (WidgetTester tester) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformUserDetailPage(userId: 'missing-user', iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Không tìm thấy'), findsOneWidget);
  });

  testWidgets('suspend action updates status badge', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(scenario: FakeIamScenario.suspendOk);

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformUserDetailPage(userId: 'lan-le', iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạm ngừng người dùng'));
    await tester.pumpAndSettle();

    final reasonField = find.byType(TextField);
    expect(reasonField, findsWidgets);
    await tester.enterText(reasonField.first, 'vi phạm');
    await tester.tap(find.text('Tạm ngừng').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã tạm ngừng'), findsOneWidget);
  });
}
