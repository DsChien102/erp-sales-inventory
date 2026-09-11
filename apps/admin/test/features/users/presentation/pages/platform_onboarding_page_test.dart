import 'package:admin/features/organizations/presentation/pages/platform_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/testing.dart';

/// wgt_e01_u03_fr01_01 — Onboarding wizard via IIamModule.
void main() {
  testWidgets('shows owner step and search results from FakeIamModule', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(
      scenario: FakeIamScenario.onboardingExistingUserOk,
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khởi tạo tổ chức'), findsOneWidget);

    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();

    expect(find.text('Lê Thị Lan'), findsWidgets);
  });

  testWidgets('validation blocks next without owner selection', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.textContaining('chủ sở hữu'), findsWidgets);
  });

  testWidgets('offers new owner creation in onboarding', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo mới'), findsOneWidget);

    await tester.tap(find.text('Tạo mới'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập họ và tên đệm'), findsOneWidget);
    expect(find.text('Nhập tên'), findsOneWidget);
    expect(find.text('Nhập email'), findsOneWidget);
    expect(find.text('Vai trò mặc định'), findsOneWidget);
  });

  testWidgets('new owner onboarding reaches review and submits successfully', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo mới'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
    await tester.enterText(find.byType(TextField).at(1), 'An');
    await tester.enterText(find.byType(TextField).at(2), 'new@example.com');
    await tester.enterText(find.byType(TextField).at(3), '0909123456');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Phong kham moi');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Nguyen An'), findsOneWidget);
    expect(find.text('new@example.com'), findsWidgets);
    expect(find.text('Phong kham moi'), findsWidgets);

    await tester.tap(find.widgetWithText(VButton, 'Khởi tạo tổ chức'));
    await tester.pumpAndSettle();

    expect(find.text('Phong kham moi'), findsWidgets);
  });

  testWidgets(
    'review step shows status note and owner details',
    (WidgetTester tester) async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.onboardingNewUserOk,
      );

      await tester.pumpWidget(
        MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
      await tester.enterText(find.byType(TextField).at(1), 'An');
      await tester.enterText(find.byType(TextField).at(2), 'new@example.com');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Phong kham moi');
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Đang thiết lập'), findsWidgets);
      expect(find.textContaining('new@example.com'), findsWidgets);
    },
  );

  testWidgets('organization step fields are submitted to onboarding command', (
    WidgetTester tester,
  ) async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk),
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo mới'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
    await tester.enterText(find.byType(TextField).at(1), 'An');
    await tester.enterText(find.byType(TextField).at(2), 'new@example.com');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Phong kham moi');
    await tester.enterText(find.byType(TextField).at(1), '0909123456');
    await tester.enterText(find.byType(TextField).at(2), 'contact@example.com');
    await tester.enterText(find.byType(TextField).at(3), '123 Main');
    await tester.enterText(find.byType(TextField).at(7), 'Cong ty PK Moi');
    await tester.enterText(find.byType(TextField).at(8), '0123456789');
    await tester.enterText(find.byType(TextField).at(9), '456 Legal St');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Khởi tạo tổ chức'));
    await tester.pumpAndSettle();

    final command = module.commandsOf<CreateTenantOnboardingCommand>().single;
    expect(command.organizationName, 'Phong kham moi');
    expect(command.contactPhone, '0909123456');
    expect(command.contactEmail, 'contact@example.com');
    expect(command.contactAddressText, '123 Main');
    expect(command.legalName, 'Cong ty PK Moi');
    expect(command.taxCode, '0123456789');
    expect(command.registeredAddressText, '456 Legal St');
  });

  testWidgets('new owner invalid email is blocked before organization step', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo mới'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
    await tester.enterText(find.byType(TextField).at(1), 'An');
    await tester.enterText(find.byType(TextField).at(2), 'khong-hop-le');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);
    expect(find.text('Tên tổ chức'), findsNothing);
  });

  testWidgets('organization step does not prefill hardcoded province or ward', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(
      scenario: FakeIamScenario.onboardingExistingUserOk,
    );

    await tester.pumpWidget(
      MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lê Thị Lan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Đồng Nai'), findsNothing);
    expect(find.text('Trấn Biên'), findsNothing);
  });

  testWidgets(
    'new owner with existing email shows warning banner and locks continue button',
    (WidgetTester tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

      await tester.pumpWidget(
        MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Lê');
      await tester.enterText(find.byType(TextField).at(1), 'Lan');
      await tester.enterText(find.byType(TextField).at(2), 'lan@gmail.com');
      await tester.pumpAndSettle();

      // Bấm Tiếp tục
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      // Banner cảnh báo xuất hiện
      expect(find.byType(VBanner), findsOneWidget);
      expect(find.text('Email đã có tài khoản'), findsOneWidget);
      expect(
        find.text('Vui lòng quay lại để chọn tài khoản hiện có.'),
        findsOneWidget,
      );

      // Nút Tiếp tục bị khóa (onPressed == null)
      final continueBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Tiếp tục'),
      );
      expect(continueBtn.onPressed, isNull);

      // Không chuyển sang bước 2
      expect(find.text('Tên tổ chức'), findsNothing);
    },
  );

  testWidgets(
    'editing email clears duplicate banner and re-enables continue button',
    (WidgetTester tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

      await tester.pumpWidget(
        MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Lê');
      await tester.enterText(find.byType(TextField).at(1), 'Lan');
      await tester.enterText(find.byType(TextField).at(2), 'lan@gmail.com');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.byType(VBanner), findsOneWidget);

      // Sửa email thành email mới
      await tester.enterText(find.byType(TextField).at(2), 'lan_new@gmail.com');
      await tester.pumpAndSettle();

      // Banner biến mất và nút Tiếp tục mở khóa
      expect(find.byType(VBanner), findsNothing);
      final continueBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Tiếp tục'),
      );
      expect(continueBtn.onPressed, isNotNull);

      // Bấm Tiếp tục đi tiếp sang bước 2 thành công
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Tên tổ chức'), findsOneWidget);
    },
  );

  testWidgets(
    'toggling between new owner and existing owner clears duplicate email flag',
    (WidgetTester tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk);

      await tester.pumpWidget(
        MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Lê');
      await tester.enterText(find.byType(TextField).at(1), 'Lan');
      await tester.enterText(find.byType(TextField).at(2), 'lan@gmail.com');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.byType(VBanner), findsOneWidget);

      // Bấm Quay lại để về màn chọn có sẵn
      await tester.tap(find.widgetWithText(VButton, 'Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Tạo mới'), findsOneWidget);

      // Bấm lại Tạo mới -> Banner không còn hiện
      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      expect(find.byType(VBanner), findsNothing);
    },
  );

  testWidgets(
    'fail-closed: query failure blocks progression and displays error toast',
    (WidgetTester tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.userForbidden403);

      await tester.pumpWidget(
        MaterialApp(home: PlatformOnboardingPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
      await tester.enterText(find.byType(TextField).at(1), 'An');
      await tester.enterText(find.byType(TextField).at(2), 'any@example.com');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      // Toast lỗi xuất hiện và bị chặn không chuyển bước
      expect(find.byType(VToast), findsOneWidget);
      expect(find.text('Vui lòng kiểm tra kết nối và thử lại.'), findsOneWidget);
      expect(find.text('Tên tổ chức'), findsNothing);
    },
  );
}
