import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import 'widgets/erp_bottom_navigation.dart';
import 'widgets/tenant_ready_gate.dart';

/// Top-level tab scaffold holding the [StatefulNavigationShell] with 5 branches.
///
/// Under desktop width (≥ 1024), only [navigationShell] is rendered (the desktop
/// sidebar is provided outside by [StoreShell]).
/// On mobile / narrow screens (< 1024), renders [Scaffold] with [ErpBottomNavigation].
class ErpTabScaffold extends StatelessWidget {
  const ErpTabScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    Widget content = navigationShell;
    if (navigationShell.currentIndex != ErpTab.more.index) {
      content = TenantReadyGate(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= VBreakpoints.desktop;
        if (isDesktop) {
          return content;
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: ErpBottomNavigation(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        );
      },
    );
  }
}
