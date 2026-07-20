import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/admin_tab.dart';

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
          path: 'dashboard/organizations',
          builder: (context, state) => const DashboardPage(initialTab: AdminTab.organizations),
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
