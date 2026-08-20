import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import 'models/admin_tab.dart';
import '../../overview/presentation/pages/admin_overview_page.dart';
import '../../users/presentation/pages/platform_users_page.dart';
import '../../organizations/presentation/pages/organizations_page.dart';
import '../../audit/presentation/pages/audit_logs_page.dart';
import '../../more/presentation/pages/more_page.dart';
import 'widgets/admin_bottom_navigation.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialTab = AdminTab.home});

  final AdminTab initialTab;

  static void navigateToTab(BuildContext context, AdminTab tab) {
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
  late AdminTab _currentTab;
  int? _platformUsersCount;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.enabled ? widget.initialTab : AdminTab.home;
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentTab = widget.initialTab.enabled
          ? widget.initialTab
          : AdminTab.home;
    }
  }

  void setTab(AdminTab tab) {
    if (!tab.enabled || _currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    context.goNamed('dashboard', extra: tab);
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentTab) {
      case AdminTab.home:
        return const AdminOverviewPage();
      case AdminTab.users:
        return PlatformUsersPage(
          onUserCountChanged: (count) {
            if (_platformUsersCount != count) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _platformUsersCount = count);
                }
              });
            }
          },
        );
      case AdminTab.organizations:
        return const OrganizationsPage();
      case AdminTab.audit:
        return const AuditLogsPage();
      case AdminTab.more:
        return const MorePage();
    }
  }

  String _getTabTitle(AdminTab tab) {
    switch (tab) {
      case AdminTab.home:
        return 'Tổng quan quản trị';
      case AdminTab.users:
        return 'Người dùng nền tảng';
      case AdminTab.organizations:
        return 'Tổ chức';
      case AdminTab.audit:
        return 'Nhật ký nền tảng';
      case AdminTab.more:
        return 'Cài đặt thêm';
    }
  }

  String? _getTabSubtitle(AdminTab tab) {
    if (tab == AdminTab.users && _platformUsersCount != null) {
      return '$_platformUsersCount người dùng';
    }
    return null;
  }

  List<Widget>? _getTabActions(AdminTab tab) {
    if (tab == AdminTab.home) {
      return [
        IconButton(
          icon: const VIcon(icon: VIcons.moreHoriz),
          onPressed: () {},
        ),
      ];
    }
    return null;
  }

  Widget? _buildFloatingActionButton() {
    if (_currentTab == AdminTab.organizations) {
      return VFloatingActionButton(
        icon: VIcons.add,
        onTap: () => context.pushNamed('onboarding_wizard'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: _getTabTitle(_currentTab),
        subtitle: _getTabSubtitle(_currentTab),
        actions: _getTabActions(_currentTab),
        showBackButton: false,
      ),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: _currentTab.index,
        onItemSelected: (index) {
          final tab = AdminTab.values[index];
          setTab(tab);
        },
      ),
    );
  }
}
