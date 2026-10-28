import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/session/session_controller.dart';
import '../../../more/presentation/more_entries.dart';
import '../../../more/presentation/more_logout.dart';
import '../../../tenant_context/presentation/tenant_context_selector.dart';
import 'erp_bottom_navigation.dart';

/// Desktop side navigation rail for the store area.
class ErpSideNavigation extends StatelessWidget {
  const ErpSideNavigation({
    super.key,
    this.currentLocation,
  });

  final String? currentLocation;

  @override
  Widget build(BuildContext context) {
    final location = currentLocation ?? GoRouterState.of(context).matchedLocation;
    final sessionState = context.watch<SessionController>().state;
    final isOwner = sessionState.current?.isOwner == true;
    final isBlocked = sessionState.isBlocked;
    final orgName = sessionState.current?.tenantName ?? 'Chưa chọn tổ chức';

    final selectedTab = ErpTab.fromLocation(location);
    final mainIndex = selectedTab.index;

    final visibleSubEntries = kSideNavSubEntries.where((entry) {
      if (entry.ownerOnly && !isOwner && !isBlocked) return false;
      return true;
    }).toList();

    int? subIndex;
    if (selectedTab == ErpTab.more) {
      final selectedSub = selectedMoreEntry(location);
      if (selectedSub != null) {
        final idx = visibleSubEntries.indexWhere((e) => e.id == selectedSub.id);
        if (idx >= 0) subIndex = idx;
      }
    }

    final sideNavItems = ErpTab.values.map((tab) {
      if (tab == ErpTab.more) {
        return VSideNavigationItem(
          icon: Icon(tab.icon),
          label: tab.label,
          enabled: tab.enabled,
          children: visibleSubEntries.map((sub) {
            return VSideNavigationItem(
              label: sub.title,
              enabled: sub.isInteractive(isBlocked: isBlocked),
            );
          }).toList(),
        );
      }
      return VSideNavigationItem(
        icon: Icon(tab.icon),
        label: tab.label,
        enabled: tab.enabled,
      );
    }).toList();

    return VSideNavigation(
      width: 240,
      selected: (mainIndex, subIndex),
      header: _SideNavHeader(
        orgName: orgName,
        onTap: () => openTenantContextSelector(context),
      ),
      footer: _SideNavFooter(
        onTap: () => signOutAndGoToLogin(context),
      ),
      items: sideNavItems,
      onSelect: (itemIndex, childIndex) {
        if (childIndex == null) {
          final targetTab = ErpTab.values[itemIndex];
          context.go(targetTab.routePath);
        } else {
          final targetSub = visibleSubEntries[childIndex];
          if (targetSub.route != null) {
            context.go(targetSub.route!);
          }
        }
      },
    );
  }
}

class _SideNavHeader extends StatefulWidget {
  const _SideNavHeader({
    required this.orgName,
    required this.onTap,
  });

  final String orgName;
  final VoidCallback onTap;

  @override
  State<_SideNavHeader> createState() => _SideNavHeaderState();
}

class _SideNavHeaderState extends State<_SideNavHeader> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderRadius = BorderRadius.circular(VRadius.r8);

    return Semantics(
      button: true,
      label: 'Đổi tổ chức, ${widget.orgName}',
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: VSpacing.space2,
          vertical: VSpacing.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: _isFocused
              ? Border.all(color: colors.primary, width: VBorders.thick)
              : Border.all(color: Colors.transparent, width: VBorders.thick),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            focusColor: colors.primary.withValues(alpha: 0.12),
            hoverColor: colors.surfaceHover,
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space2,
                vertical: VSpacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.orgName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VTypography.headingH4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  VIcon(
                    icon: VIcons.swapVert,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavFooter extends StatefulWidget {
  const _SideNavFooter({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_SideNavFooter> createState() => _SideNavFooterState();
}

class _SideNavFooterState extends State<_SideNavFooter> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderRadius = BorderRadius.circular(VRadius.r8);

    return Semantics(
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: _isFocused
              ? Border.all(color: colors.primary, width: VBorders.thick)
              : Border.all(color: Colors.transparent, width: VBorders.thick),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            focusColor: colors.primary.withValues(alpha: 0.12),
            hoverColor: colors.surfaceHover,
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space2,
                vertical: VSpacing.space2,
              ),
              child: Row(
                children: [
                  VIcon(
                    icon: VIcons.logout,
                    size: 20,
                    color: colors.danger,
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Text(
                    'Đăng xuất',
                    style: VTypography.labelDefault.copyWith(
                      color: colors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
