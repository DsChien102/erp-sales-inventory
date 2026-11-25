import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

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
    // Sau `push`, `matchedLocation` vẫn là trang gốc; `uri` mới là trang được đẩy (10-8d Q1).
    final location = currentLocation ?? GoRouterState.of(context).uri.path;
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
        // Web: "Thêm" hiện là "Quản lý" (menu nổi); thanh dưới giữ nhãn "Thêm".
        return VSideNavigationItem(
          icon: const VIcon(icon: VIcons.layers),
          label: 'Quản lý',
          menuTitle: 'Quản lý cửa hàng',
          enabled: tab.enabled,
          children: visibleSubEntries.map((sub) {
            return VSideNavigationItem(
              icon: VIcon(icon: sub.icon),
              label: sub.title,
              description: sub.subtitle,
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
      // Đổi tổ chức thì dựng lại, gỡ menu đang mở (danh sách mục con có thể đổi).
      key: ValueKey(sessionState.current?.tenantId),
      selected: (mainIndex, subIndex),
      header: _SideNavOrgTile(
        orgName: orgName,
        showStore: isBlocked || orgName.trim().isEmpty,
        onTap: () => openTenantContextSelector(context),
      ),
      footer: VSideNavigationAction(
        icon: VIcons.logout,
        label: 'Đăng xuất',
        destructive: true,
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

/// Ô tổ chức 40×40 trên cùng thanh biểu tượng: chữ cái đầu (hoặc icon cửa hàng
/// khi bị chặn), bấm để đổi tổ chức.
class _SideNavOrgTile extends StatefulWidget {
  const _SideNavOrgTile({
    required this.orgName,
    required this.showStore,
    required this.onTap,
  });

  final String orgName;
  final bool showStore;
  final VoidCallback onTap;

  @override
  State<_SideNavOrgTile> createState() => _SideNavOrgTileState();
}

class _SideNavOrgTileState extends State<_SideNavOrgTile> {
  static const _focusGap = 4.0; // khe 2 + viền 2
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final radius = BorderRadius.circular(VRadius.r8);
    final initial = widget.showStore ? '' : widget.orgName.trim().characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space4),
      child: Center(
        child: Tooltip(
          message: widget.orgName,
          child: Semantics(
            button: true,
            label: 'Đổi tổ chức, ${widget.orgName}',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _isHovered ? colors.primaryPressed : colors.primary,
                        borderRadius: radius,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: radius,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onHover: (v) => setState(() => _isHovered = v),
                          onFocusChange: (v) => setState(() => _isFocused = v),
                          onTap: widget.onTap,
                          child: Center(
                            child: widget.showStore
                                ? VIcon(
                                    icon: VIcons.store,
                                    size: 20,
                                    color: colors.textInverse,
                                  )
                                : Text(
                                    initial,
                                    style: VTypography.headingH4.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textInverse,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Viền focus nằm ngoài ô (khe 2, dày 2) như `outline-offset: 2px`
                  // của prototype: vẽ trên nền trắng của thanh nên đủ tương phản.
                  Positioned(
                    left: -_focusGap,
                    top: -_focusGap,
                    right: -_focusGap,
                    bottom: -_focusGap,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('org-tile-focus-ring'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            VRadius.r8 + _focusGap,
                          ),
                          border: Border.all(
                            color: _isFocused ? colors.primary : Colors.transparent,
                            width: VBorders.thick,
                          ),
                        ),
                      ),
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
