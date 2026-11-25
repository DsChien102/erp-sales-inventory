import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// GoRouter giả cho test màn công khai: trang đích chỉ là `Text`, `extra` được ghi lại.
class TestRouter {
  TestRouter({required String initial, required Map<String, Widget> pages}) {
    const stubs = {
      '/login': 'LOGIN_PAGE',
      '/': 'HOME_PAGE',
      '/invitation': 'INVITATION_PAGE',
      '/login/reset-password': 'RESET_PAGE',
      '/signup': 'SIGNUP_PAGE',
      '/verify-email': 'VERIFY_PAGE',
    };
    final paths = {...stubs.keys, ...pages.keys};
    router = GoRouter(
      initialLocation: initial,
      routes: [
        for (final path in paths)
          GoRoute(
            path: path,
            builder: (context, state) {
              extras[path] = state.extra;
              return pages[path] ?? Scaffold(body: Text(stubs[path]!));
            },
          ),
      ],
    );
  }

  late final GoRouter router;
  final extras = <String, Object?>{};

  Widget app() => MaterialApp.router(
    theme: VTheme.lightTheme,
    routerConfig: router,
  );
}
