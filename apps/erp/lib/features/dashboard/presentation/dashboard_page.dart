// harness:allow-design-system-bypass — shell tab root (header/appBar có điều kiện + bottom nav), không phải page VAppBar đơn
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

import '../../../core/di/injection.dart';
import '../../tenant_context/presentation/bloc/tenant_context_cubit.dart';
import '../../tenant_context/presentation/bloc/tenant_context_state.dart';
import '../../tenant_context/presentation/tenant_context_selector.dart';
import 'models/dashboard_navigation.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/erp_bottom_navigation.dart';
import 'widgets/metric_tile.dart';
import 'widgets/revenue_summary_card.dart';
import 'widgets/task_item.dart';
import '../../more/presentation/pages/more_page.dart';
import '../../catalog/presentation/pages/product_catalog_tab_page.dart';
import '../../partner/presentation/pages/partner_list_page.dart';
import '../../sales/presentation/pages/sales_order_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.initialTab = DashboardTab.home,
    this.iamModule,
    this.autoBootstrap = true,
  });

  final DashboardTab initialTab;
  final IIamModule? iamModule;
  final bool autoBootstrap;

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
    final module = iamModule ?? getIt<IIamModule>();
    return BlocProvider(
      create: (_) {
        final cubit = TenantContextCubit(
          iamModule: module,
          applyPermissions: applyTenantContextPermissions,
        );
        if (autoBootstrap) {
          cubit.bootstrap();
        }
        return cubit;
      },
      child: _DashboardPageBody(initialTab: initialTab),
    );
  }
}

class _DashboardPageBody extends StatefulWidget {
  const _DashboardPageBody({required this.initialTab});

  final DashboardTab initialTab;

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

  Widget _buildHomeBody(BuildContext context, TenantContextState state) {
    if (state.status == TenantContextLoadStatus.loading ||
        state.status == TenantContextLoadStatus.initial) {
      return const Center(child: VLoading());
    }

    if (state.isBlocked) {
      return Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: OrganizationEmptyView(
          type: state.emptyStateType ?? OrganizationEmptyStateType.noAuthorizedOrganizations,
          suspendedOrgName: state.suspendedOrgName,
          onAction: () => _openSelector(context),
        ),
      );
    }

    if (state.status == TenantContextLoadStatus.failure) {
      return Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: OrganizationEmptyView(
          type: OrganizationEmptyStateType.loadError,
          onAction: () => context.read<TenantContextCubit>().bootstrap(),
        ),
      );
    }

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

  Widget _buildBody(BuildContext context, TenantContextState state) {
    switch (_currentTab) {
      case DashboardTab.home:
        return _buildHomeBody(context, state);
      case DashboardTab.more:
        return const MorePage();
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
    final dynamicColors = context.vColors;
    final showHeader = _currentTab == DashboardTab.home;
    final showAppBar = _currentTab == DashboardTab.more;

    return BlocBuilder<TenantContextCubit, TenantContextState>(
      builder: (context, state) {
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
      },
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
