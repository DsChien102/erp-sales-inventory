import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:go_router/go_router.dart';

import '../../features/more/presentation/pages/system_settings_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_settings_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_connection_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_template_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_auto_page.dart';
import '../../features/more/presentation/einvoice_settings/bloc/einvoice_settings_cubit.dart';
import '../../features/auth/domain/usecases/get_auth_state_use_case.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/dashboard_navigation.dart';
import '../di/injection.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = getIt<GetAuthStateUseCase>()();
    final isLoginRoute = state.matchedLocation == '/login';

    if (!auth.isAuthenticated && !isLoginRoute) {
      return '/login';
    }

    if (auth.isAuthenticated && isLoginRoute) {
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
        final tab = state.extra as DashboardTab? ?? DashboardTab.home;
        return DashboardPage(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/more/settings',
      name: 'more.settings',
      builder: (context, state) => const SystemSettingsPage(),
    ),
    GoRoute(
      path: '/more/einvoice-settings',
      name: 'more.einvoice-settings',
      builder: (context, state) {
        final authState = getIt<GetAuthStateUseCase>()();
        if (authState.email == 'no-permission@vet45.com') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bạn không có quyền thiết lập hóa đơn điện tử',
                  style: VTypography.bodyDefault.copyWith(color: VColors.neutral0),
                ),
                backgroundColor: VColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.card),
                ),
                margin: const EdgeInsets.all(VSpacing.space4),
              ),
            );
            context.go('/');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return const EInvoiceSettingsPage();
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/connection',
      name: 'more.einvoice-settings.connection',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit;
        return EInvoiceConnectionPage(cubit: cubit);
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/template',
      name: 'more.einvoice-settings.template',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit;
        return EInvoiceTemplatePage(cubit: cubit);
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/auto',
      name: 'more.einvoice-settings.auto',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit;
        return EInvoiceAutoPage(cubit: cubit);
      },
    ),
  ],
);
