import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import 'models/dashboard_navigation.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/erp_bottom_navigation.dart';
import 'widgets/metric_tile.dart';
import 'widgets/revenue_summary_card.dart';
import 'widgets/task_item.dart';
import '../../more/presentation/pages/more_page.dart';
import '../../catalog/presentation/pages/product_catalog_tab_page.dart';
import '../../partner/presentation/pages/partner_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialTab = DashboardTab.home});

  final DashboardTab initialTab;

  static void navigateToTab(BuildContext context, DashboardTab tab) {
    final state = context.findAncestorStateOfType<_DashboardPageState>();
    if (state != null) {
      state.setTab(tab);
    } else {
      context.goNamed('dashboard', extra: tab);
    }
  }

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.enabled ? widget.initialTab : DashboardTab.home;
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
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

  Widget _buildBody(BuildContext context) {
    switch (_currentTab) {
      case DashboardTab.home:
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
                  const Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: Icons.receipt_long_outlined,
                          iconColor: VColors.info,
                          iconBackgroundColor: VColors.infoBg,
                          label: 'Đơn hôm nay',
                        ),
                      ),
                      SizedBox(width: VSpacing.space2),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: VColors.warning,
                          iconBackgroundColor: VColors.warningBg,
                          label: 'Phải thu',
                        ),
                      ),
                      SizedBox(width: VSpacing.space2),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.inventory_2_outlined,
                          iconColor: VColors.danger,
                          iconBackgroundColor: VColors.dangerBg,
                          label: 'Sắp hết',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space5),
                  const _SectionHeader(title: 'Việc cần xử lý'),
                  const SizedBox(height: VSpacing.space2),
                  const TaskItem(
                    icon: Icons.handshake_outlined,
                    iconColor: VColors.danger,
                    iconBackgroundColor: VColors.dangerBg,
                  ),
                  const SizedBox(height: VSpacing.space2),
                  const TaskItem(
                    icon: Icons.inventory_2_outlined,
                    iconColor: VColors.warning,
                    iconBackgroundColor: VColors.warningBg,
                  ),
                ]),
              ),
            ),
          ],
        );
      case DashboardTab.more:
        return const MorePage();
      case DashboardTab.orders:
        return const SizedBox.shrink();
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
          Expanded(child: _buildBody(context)),
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
          child: Text(
            title,
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w600,
              color: dynamicColors.textPrimary,
            ),
          ),
        ),
        ?trailingWidget,
      ],
    );
  }
}
