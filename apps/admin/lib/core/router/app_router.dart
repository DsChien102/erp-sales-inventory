import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/admin_tab.dart';
import '../../features/users/presentation/pages/platform_user_detail_page.dart';
import '../../features/organizations/presentation/pages/platform_onboarding_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.home),
        ),
        GoRoute(
          path: 'dashboard/users',
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.users),
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
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.organizations),
        ),
        GoRoute(
          path: 'dashboard/organizations/new',
          name: 'onboarding_wizard',
          builder: (context, state) => const PlatformOnboardingPage(),
        ),
        GoRoute(
          path: 'dashboard/audit',
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.audit),
        ),
        GoRoute(
          path: 'dashboard/more',
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.more),
        ),
      ],
    ),
  ],
);
