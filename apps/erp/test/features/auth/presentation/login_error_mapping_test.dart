import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/auth/presentation/bloc/login_cubit.dart';
import 'package:erp/features/auth/presentation/bloc/login_state.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';

final class _ThrowingIamModule implements IIamModule {
  _ThrowingIamModule(this.errorToThrow);

  final Object errorToThrow;

  @override
  Future<TResult> executeCommandAsync<TResult>(dynamic command) {
    return Future.error(errorToThrow);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(dynamic query) {
    throw UnimplementedError();
  }
}

void main() {
  group('Login error mapping and presentation', () {
    test('authInvalid emits invalidCredentials with Vietnamese copy', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.authInvalid);
      final cubit = LoginCubit(iamModule: module);

      await cubit.submit(email: 'asdasd@gmail.com', password: 'secret');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.invalidCredentials);
      expect(
        cubit.state.failure?.message,
        'Email hoặc mật khẩu không chính xác.',
      );
      await cubit.close();
    });

    test('AuthException with invalid_credentials maps to user friendly message', () async {
      final module = _ThrowingIamModule(
        const AuthException('Invalid login credentials', code: 'invalid_credentials'),
      );
      final cubit = LoginCubit(iamModule: module);

      await cubit.submit(email: 'asdasd@gmail.com', password: 'secret');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.invalidCredentials);
      expect(
        cubit.state.failure?.message,
        'Email hoặc mật khẩu không chính xác.',
      );
      await cubit.close();
    });

    test('Network failure maps to server connection message', () async {
      final module = _ThrowingIamModule(
        SocketException('Failed host lookup: localhost'),
      );
      final cubit = LoginCubit(iamModule: module);

      await cubit.submit(email: 'asdasd@gmail.com', password: 'secret');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.systemError);
      expect(
        cubit.state.failure?.message,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
      );
      await cubit.close();
    });

    testWidgets('LoginPage shows invalid credentials on email VFieldError', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamModule(scenario: FakeIamScenario.authInvalid);
      final cubit = LoginCubit(iamModule: module);
      addTearDown(cubit.close);

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(cubit: cubit),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'asdasd@gmail.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Email hoặc mật khẩu không chính xác.'), findsOneWidget);
      expect(find.byType(VFieldError), findsOneWidget);
      expect(find.text('Đăng nhập thất bại'), findsNothing);
      expect(find.text('Đã xảy ra lỗi hệ thống. Vui lòng thử lại.'), findsNothing);
    });
  });
}
