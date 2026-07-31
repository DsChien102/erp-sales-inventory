import 'package:erp/features/my_account/presentation/bloc/my_account_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

/// e2e_e06_u01/u02/u03/u04 — ERP My Account via FakeIamModule (Group E / S14).
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void registerModule(FakeIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IIamModule>(module);
  }

  Widget wrap(FakeIamModule module) {
    final router = GoRouter(
      initialLocation: '/more/my-account',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login')),
          ),
        ),
        GoRoute(
          path: '/more/my-account',
          builder: (context, state) => BlocProvider(
            create: (_) => MyAccountCubit(iamModule: module)..load(),
            child: MyAccountPage(
              iamModule: module,
              onLogout: () async {
                await module.executeCommandAsync(SignOutCommand());
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('e2e_e06_u01_fr01_01: load my profile', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.myAccountOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsOneWidget);
    expect(find.text('Lan Le'), findsOneWidget);
    expect(find.text('lan@gmail.com'), findsOneWidget);
  });

  testWidgets('e2e_e06_u02_fr01_01: edit profile save', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.myAccountUpdateOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa thông tin cá nhân'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa thông tin'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Trần Văn');
    await tester.enterText(fields.at(1), 'A');
    await tester.pump();

    await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Trần Văn A'), findsOneWidget);
  });

  testWidgets('e2e_e06_u03_fr01_01: password reset happy path', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.passwordResetCompleteOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt lại mật khẩu'), findsWidgets);

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '123456');
    await tester.pump();
    await tester.tap(find.text('Xác nhận mã'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo mật khẩu mới'), findsOneWidget);

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), 'password1');
    await tester.enterText(passwordFields.at(1), 'password1');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản của tôi'), findsOneWidget);
  });

  testWidgets('e2e_e06_u04_fr01_01: logout clears session', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamModule(scenario: FakeIamScenario.myAccountOk);
    registerModule(module);

    await tester.pumpWidget(wrap(module));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất khỏi VET45?'), findsOneWidget);
    await tester.tap(find.widgetWithText(VButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(module.signOutCount, 1);
    expect(find.text('Login'), findsOneWidget);
  });
}
