import 'package:erp/features/auth/presentation/pages/account_activation_page.dart';
import 'package:erp/features/auth/presentation/pages/activation_code_page.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

Widget _buildTestWidget({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LoginPage(
            prefilledEmail: extra?['prefilledEmail'] as String?,
            showSuccessBanner: extra?['showSuccessBanner'] as bool? ?? false,
          );
        },
        routes: [
          GoRoute(
            path: 'enter-code',
            builder: (context, state) => const ActivationCodePage(),
          ),
          GoRoute(
            path: 'activate',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AccountActivationPage(
                email: extra?['email'] as String?,
              );
            },
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
  );
}

void main() {
  group('Login & Account Activation Flow Tests', () {
    testWidgets('Screen 1 (ID-D-00) renders correctly and navigates to Screen 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget(initialLocation: '/login'));
      await tester.pumpAndSettle();

      expect(find.text('VET45'), findsOneWidget);
      expect(find.text('Quản trị bán hàng thuốc thú y'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Số điện thoại hoặc email'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Mật khẩu'),
        ),
        findsOneWidget,
      );
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Kích hoạt tài khoản'), findsOneWidget);

      // Tap "Kích hoạt tài khoản" -> Screen 2
      await tester.tap(find.text('Kích hoạt tài khoản'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập mã kích hoạt'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Mã kích hoạt'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Flow 1 (Existing Account): Code 123456 returns to Login with Success Banner & Email (Screen 1 -> 2 -> 4)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget(initialLocation: '/login/enter-code'));
      await tester.pumpAndSettle();

      // Enter fake code 123456
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '123456');
      await tester.pumpAndSettle();

      // Tap "Tiếp tục"
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      // Should be back at Login Page with Success Banner & Prefilled email
      expect(find.text('Mã kích hoạt hợp lệ'), findsOneWidget);
      expect(
        find.text('Đăng nhập đúng tài khoản để tiếp nhận lời mời và vào VET45.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'nhhaha@gmail.com',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Flow 2 (New Account): Code != 123456 navigates to Screen 3, validates fields, and activates account (Screen 1 -> 2 -> 3 -> Toast)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestWidget(initialLocation: '/login/enter-code'));
      await tester.pumpAndSettle();

      // Enter code other than 123456
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'V45-A7K9-P2DX');
      await tester.pumpAndSettle();

      // Tap "Tiếp tục"
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      // Should navigate to Screen 3 (AccountActivationPage)
      expect(find.text('Mã kích hoạt hợp lệ'), findsOneWidget);
      expect(
        find.text('Kích hoạt tài khoản để tiếp nhận lời mời và vào VET45.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Họ và tên đệm'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Tên'),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'nhhaha@gmail.com',
        ),
        findsOneWidget,
      );

      // Attempt to submit empty form -> triggers validation errors & danger VToast
      await tester.tap(find.widgetWithText(VButton, 'Kích hoạt tài khoản'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ và tên đệm'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.text('Vui lòng nhập lại mật khẩu'), findsOneWidget);

      // Fill in required fields
      final fields = find.byType(TextField);
      // Field 0: Họ và tên đệm
      await tester.enterText(fields.at(0), 'Nguyễn Văn');
      // Field 1: Tên
      await tester.enterText(fields.at(1), 'An');
      // Field 4: Mật khẩu
      await tester.enterText(fields.at(4), 'Password123');
      // Field 5: Xác nhận mật khẩu
      await tester.enterText(fields.at(5), 'Password123');
      await tester.pumpAndSettle();

      // Submit valid form
      await tester.tap(find.widgetWithText(VButton, 'Kích hoạt tài khoản'));
      await tester.pumpAndSettle();

      // Verify redirected back to /login
      expect(find.text('VET45'), findsOneWidget);
    });
  });
}
