// harness:allow-design-system-bypass — shell tab root (header/appBar có điều kiện + bottom nav), không phải page VAppBar đơn
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

import '../../../core/di/injection.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_state.dart';
import '../../tenant_context/presentation/tenant_context_selector.dart';
import 'bloc/default_pair_gate_cubit.dart';
import 'models/dashboard_navigation.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/default_pair_gate_error_view.dart';
import 'widgets/erp_bottom_navigation.dart';
import 'widgets/metric_tile.dart';
import 'widgets/revenue_summary_card.dart';
import 'widgets/task_item.dart';
import '../../more/presentation/pages/more_page.dart';
import '../../catalog/presentation/pages/product_catalog_tab_page.dart';
import '../../partner/presentation/pages/partner_list_page.dart';
import '../../sales/presentation/pages/sales_order_list_page.dart';

/// Signs out and navigates to login when the platform account is suspended.
/// Always navigates even if remote sign-out fails (network).
Future<void> signOutSuspendedAccountAndGoToLogin(
  BuildContext context, {
  bool showToast = true,
}) async {
  if (showToast) {
    VToast.show(
      context,
      title: 'Tài khoản bị tạm ngừng',
      message: 'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
      type: VToastType.danger,
    );
  }
  try {
    await getIt<SessionController>().signOut();
  } catch (_) {}
  if (!context.mounted) return;
  context.go('/login');
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.initialTab = DashboardTab.home,
    this.iamModule,
    this.inventoryModule,
    this.autoBootstrap = true,
    this.initialState,
  });

  final DashboardTab initialTab;
  final IIamModule? iamModule;
  final IInventoryModule? inventoryModule;
  final bool autoBootstrap;
  final SessionState? initialState;

  static void navigateToTab(BuildContext context, DashboardTab tab) {
    final state = context.findAncestorStateOfType<_DashboardPageState>();
    if (state != null) {
      state.setTab(tab);
    } else {
      context.goNamed('dashboard', extra: tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _DashboardPageBody(
      initialTab: initialTab,
      inventoryModule: inventoryModule,
    );
    // Test truyền module/state riêng: cubit cục bộ, được đóng khi rời widget.
    // App thật dùng singleton — BlocProvider(create:) sẽ close() nó khi rời Dashboard.
    if (iamModule != null || initialState != null) {
      return BlocProvider(
        create: (_) {
          final cubit = SessionController(
            iamModule: iamModule ?? getIt<IIamModule>(),
            initialState: initialState,
          );
          if (autoBootstrap) {
            cubit.bootstrap();
          }
          return cubit;
        },
        child: body,
      );
    }

    return BlocProvider.value(
      value: getIt<SessionController>(),
      child: _SessionBootstrap(
        enabled: autoBootstrap,
        child: body,
      ),
    );
  }
}

class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<_SessionBootstrap> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SessionController>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DashboardPageBody extends StatefulWidget {
  const _DashboardPageBody({
    required this.initialTab,
    required this.inventoryModule,
  });

  final DashboardTab initialTab;
  final IInventoryModule? inventoryModule;

  @override
  State<_DashboardPageBody> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPageBody> {
  late DashboardTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.enabled ? widget.initialTab : DashboardTab.home;
  }

  @override
  void didUpdateWidget(covariant _DashboardPageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentTab = widget.initialTab.enabled ? widget.initialTab : DashboardTab.home;
    }
  }

  void setTab(DashboardTab tab) {
    if (!tab.enabled || _currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    context.goNamed('dashboard', extra: tab);
  }

  Future<void> _openSelector(BuildContext context) => openTenantContextSelector(context);

  Widget _buildHomeBody(BuildContext context, SessionState state) {
    final dynamicColors = context.vColors;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.screenMobile,
            VSpacing.space2,
            VSpacing.screenMobile,
            VSpacing.space4,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: VSpacing.space5),
              const _SectionHeader(title: 'Tổng quan hôm nay'),
              const SizedBox(height: VSpacing.space2),
              const RevenueSummaryCard(),
              const SizedBox(height: VSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: dynamicColors.info,
                      iconBackgroundColor: dynamicColors.infoBg,
                      label: 'Đơn hôm nay',
                    ),
                  ),
                  SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: dynamicColors.warning,
                      iconBackgroundColor: dynamicColors.warningBg,
                      label: 'Phải thu',
                    ),
                  ),
                  SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: dynamicColors.danger,
                      iconBackgroundColor: dynamicColors.dangerBg,
                      label: 'Sắp hết',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space5),
              const _SectionHeader(title: 'Việc cần xử lý'),
              const SizedBox(height: VSpacing.space2),
              TaskItem(
                icon: Icons.handshake_outlined,
                badgeStatus: VBadgeStatus.danger,
              ),
              const SizedBox(height: VSpacing.space2),
              TaskItem(
                icon: Icons.inventory_2_outlined,
                badgeStatus: VBadgeStatus.warning,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SessionState state) {
    // Tab "Khác" luôn mở: chứa Đăng xuất + Tài khoản của tôi.
    if (_currentTab != DashboardTab.more) {
      if (state.status == TenantLoadStatus.loading || state.status == TenantLoadStatus.initial) {
        return const SafeArea(child: Center(child: VLoading()));
      }

      if (state.isBlocked) {
        final accountSuspended = state.blockedErrorCode == IamBlockedCodes.platformUserSuspended;
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: OrganizationEmptyView(
                type: state.emptyStateType ?? OrganizationEmptyStateType.noAuthorizedOrganizations,
                suspendedOrgName: state.suspendedOrgName,
                isClosed: state.blockedErrorCode == IamBlockedCodes.tenantClosed,
                isAccountSuspended: accountSuspended,
                onAction: accountSuspended
                    ? () => signOutSuspendedAccountAndGoToLogin(
                        context,
                        showToast: false,
                      )
                    : () => _openSelector(context),
              ),
            ),
          ),
        );
      }

      if (state.status == TenantLoadStatus.failure) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: OrganizationEmptyView(
                type: OrganizationEmptyStateType.loadError,
                onAction: () => context.read<SessionController>().bootstrap(),
              ),
            ),
          ),
        );
      }
    }

    switch (_currentTab) {
      case DashboardTab.home:
        return _buildHomeBody(context, state);
      case DashboardTab.more:
        return MorePage(
          tenantBlocked: state.isBlocked,
        );
      case DashboardTab.orders:
        return const SalesOrderListPage();
      case DashboardTab.products:
        return const ProductCatalogTabPage();
      case DashboardTab.partners:
        return const PartnerListPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionController, SessionState>(
          listenWhen: (previous, current) => !previous.identityRevoked && current.identityRevoked,
          listener: (context, state) {
            signOutSuspendedAccountAndGoToLogin(context);
          },
        ),
        BlocListener<SessionController, SessionState>(
          // bootstrap() phát loading trước blocked → không so với `ready`.
          listenWhen: (previous, current) => !previous.isBlocked && current.isBlocked,
          listener: (context, state) {
            // Chỉ toast + về dashboard khi tổ chức tạm ngừng/đóng (đang ở trang con).
            // Bỏ qua: chưa có org; tài khoản bị tạm ngừng (sign-out qua identityRevoked).
            final orgBlocked =
                state.blockedErrorCode == IamBlockedCodes.tenantSuspended ||
                state.blockedErrorCode == IamBlockedCodes.tenantClosed;
            if (!orgBlocked) return;

            VToast.show(
              context,
              title: 'Tổ chức không thể truy cập',
              message: state.blockedErrorCode == IamBlockedCodes.tenantClosed
                  ? 'Tổ chức đã đóng.'
                  : 'Tổ chức đang bị tạm ngừng.',
              type: VToastType.danger,
            );
            context.goNamed('dashboard', extra: DashboardTab.home);
          },
        ),
      ],
      child: BlocBuilder<SessionController, SessionState>(
        builder: (context, state) {
          if (!state.isValid) {
            return _buildScaffold(context, state);
          }
          return BlocProvider(
            key: ValueKey(state.current?.tenantId),
            create: (_) {
              final module = widget.inventoryModule ?? getIt<IInventoryModule>();
              return DefaultPairGateCubit(inventoryModule: module)..load();
            },
            child: BlocBuilder<DefaultPairGateCubit, DefaultPairGateState>(
              builder: (context, gate) {
                if (gate.status != DefaultPairGateStatus.ready) {
                  return _buildGateHold(context, gate);
                }
                return _buildScaffold(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGateHold(BuildContext context, DefaultPairGateState gate) {
    final dynamicColors = context.vColors;
    return Scaffold(
      backgroundColor: dynamicColors.background,
      body: gate.status == DefaultPairGateStatus.loading
          ? const Center(child: VLoading())
          : SafeArea(
              child: DefaultPairGateErrorView(
                onRetry: () => context.read<DefaultPairGateCubit>().load(),
                onChooseOrganization: () => _openSelector(context),
              ),
            ),
    );
  }

  Widget _buildScaffold(BuildContext context, SessionState state) {
    final dynamicColors = context.vColors;
    final showHeader = _currentTab == DashboardTab.home;
    final showAppBar = _currentTab == DashboardTab.more;
    return Scaffold(
      backgroundColor: dynamicColors.background,
      appBar: showAppBar
          ? VAppBar(
              title: _getTabTitle(_currentTab),
              showBackButton: false,
            )
          : null,
      body: Column(
        children: [
          if (showHeader) const DashboardHeader(),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
      bottomNavigationBar: ErpBottomNavigation(
        selectedIndex: _currentTab.index,
        onItemSelected: (index) {
          final tab = DashboardTab.fromIndex(index);
          setTab(tab);
        },
      ),
    );
  }

  String _getTabTitle(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.more:
        return 'Thêm';
      default:
        return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  // ignore: unused_element_parameter
  const _SectionHeader({required this.title, this.trailingWidget});

  final String title;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Row(
      children: [
        Expanded(
          child: VText(
            title,
            variant: VTextVariant.bodyDefault,
            color: dynamicColors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ?trailingWidget,
      ],
    );
  }
}
