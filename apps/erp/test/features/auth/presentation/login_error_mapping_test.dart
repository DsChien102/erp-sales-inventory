import 'dart:io';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/login_cubit.dart';
import 'package:erp/features/auth/logic/login_state.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../support/scripted_auth.dart';

void main() {
  group('Login error mapping and presentation', () {
    test('authInvalid emits invalidCredentials with Vietnamese copy', () async {
      final cubit = LoginCubit(
        auth: ScriptedAuthRepository(
          signInError: const IamBlockedException(IamBlockedCodes.invalidCredentials),
        ),
        session: loginSession(),
      );

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
      final cubit = LoginCubit(
        auth: ScriptedAuthRepository(
          signInError: const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        ),
        session: loginSession(),
      );

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
      final cubit = LoginCubit(
        auth: ScriptedAuthRepository(
          signInError: const SocketException('Failed host lookup: localhost'),
        ),
        session: loginSession(),
      );

      await cubit.submit(email: 'asdasd@gmail.com', password: 'secret');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.failure?.code, IamBlockedCodes.systemError);
      expect(
        cubit.state.failure?.message,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
      );
      await cubit.close();
    });

    test('repository wraps AuthException before the cubit maps it', () async {
      final cubit = LoginCubit(
        auth: ScriptedAuthRepository(
          signInError: AppException.from(
            const AuthException('Invalid login credentials', code: 'invalid_credentials'),
          ),
        ),
        session: loginSession(),
      );

      await cubit.submit(email: 'asdasd@gmail.com', password: 'secret');

      expect(cubit.state.failure?.code, IamBlockedCodes.invalidCredentials);
      await cubit.close();
    });

    testWidgets('LoginPage shows invalid credentials on email VFieldError', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = LoginCubit(
        auth: ScriptedAuthRepository(
          signInError: const IamBlockedException(IamBlockedCodes.invalidCredentials),
        ),
        session: loginSession(),
      );
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
