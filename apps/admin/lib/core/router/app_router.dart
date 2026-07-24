import 'package:go_router/go_router.dart';
import 'package:vet45_shared_application/application.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/admin_tab.dart';
import '../../features/users/presentation/pages/platform_user_detail_page.dart';
import '../../features/organizations/presentation/pages/platform_onboarding_page.dart';
import '../di/injection.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = getIt<ICurrentUser>().userId != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoginRoute) {
      return '/login';
    }

    if (isAuthenticated && isLoginRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) {
        final tab = state.extra as AdminTab? ?? AdminTab.home;
        return DashboardPage(initialTab: tab);
      },
      routes: [
        GoRoute(
          path: 'dashboard/home',
          builder: (context, state) =>
              const DashboardPage(initialTab: AdminTab.home),
        ),
        GoRoute(
          path: 'dashboard/users',
          builder: (context, state) =>
              const DashboardPage(initialTab: AdminTab.users),
        ),
        GoRoute(
          path: 'dashboard/users/:userId',
          name: 'user_detail',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return PlatformUserDetailPage(userId: userId);
          },
        ),
        GoRoute(
          path: 'dashboard/organizations',
          builder: (context, state) =>
              const DashboardPage(initialTab: AdminTab.organizations),
        ),
        GoRoute(
          path: 'dashboard/organizations/new',
          name: 'onboarding_wizard',
          builder: (context, state) => const PlatformOnboardingPage(),
        ),
        GoRoute(
          path: 'dashboard/audit',
          builder: (context, state) =>
              const DashboardPage(initialTab: AdminTab.audit),
        ),
        GoRoute(
          path: 'dashboard/more',
          builder: (context, state) =>
              const DashboardPage(initialTab: AdminTab.more),
        ),
      ],
    ),
  ],
);
