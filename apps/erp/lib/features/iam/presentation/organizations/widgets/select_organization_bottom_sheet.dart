import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../../shared/iam_role_label_mapper.dart';
import 'confirm_switch_organization_bottom_sheet.dart';
import 'organization_empty_view.dart';

/// VBottomSheet Chọn tổ chức (TA-O-01 — Chọn tổ chức).
class SelectOrganizationBottomSheet extends StatefulWidget {
  final List<AccessibleTenant> organizations;
  final ValueChanged<AccessibleTenant>? onOrganizationSelected;
  final OrganizationEmptyStateType? emptyStateType;
  final VoidCallback? onEmptyAction;

  /// When non-null, "Thử lại" on [OrganizationEmptyStateType.loadError] calls
  /// this and replaces the sheet content with the returned list (or keeps
  /// loadError when the future returns `null`).
  final Future<List<AccessibleTenant>?> Function()? onRetryLoad;

  const SelectOrganizationBottomSheet({
    super.key,
    this.organizations = const [],
    this.onOrganizationSelected,
    this.emptyStateType,
    this.onEmptyAction,
    this.onRetryLoad,
  });

  @override
  State<SelectOrganizationBottomSheet> createState() => _SelectOrganizationBottomSheetState();
}

class _SelectOrganizationBottomSheetState extends State<SelectOrganizationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<AccessibleTenant> _organizations;
  OrganizationEmptyStateType? _emptyStateType;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _organizations = List<AccessibleTenant>.of(widget.organizations);
    _emptyStateType = widget.emptyStateType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AccessibleTenant> get _filteredOrganizations {
    if (_searchQuery.isEmpty) return _organizations;
    return _organizations.where((org) {
      return org.name.toLowerCase().contains(_searchQuery) ||
          org.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _handleSelectOrganization(AccessibleTenant org) {
    if (org.isCurrent) return;
    widget.onOrganizationSelected?.call(org);
    Navigator.of(context).pop(org);
  }

  Future<void> _handleEmptyAction() async {
    if (_emptyStateType == OrganizationEmptyStateType.loadError && widget.onRetryLoad != null) {
      if (_retrying) return;
      setState(() => _retrying = true);
      try {
        final refreshed = await widget.onRetryLoad!();
        if (!mounted) return;
        if (refreshed != null) {
          setState(() {
            _organizations = List<AccessibleTenant>.of(refreshed);
            _emptyStateType = refreshed.isEmpty
                ? OrganizationEmptyStateType.noAuthorizedOrganizations
                : null;
            _retrying = false;
          });
          return;
        }
      } finally {
        if (mounted && _retrying) {
          setState(() => _retrying = false);
        }
      }
      return;
    }
    widget.onEmptyAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final items = _filteredOrganizations;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: VText(
              'Chọn tổ chức',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const VGap.md(),
          VSearchBar(
            hintText: 'Tìm theo tên hoặc mã tổ chức',
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
          const VGap.md(),
          if (_retrying)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VSpacing.space6),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_emptyStateType != null)
            OrganizationEmptyView(
              type: _emptyStateType!,
              onAction: _handleEmptyAction,
              isCompact: true,
            )
          else if (items.isEmpty)
            _searchQuery.isNotEmpty
                ? OrganizationEmptyView(
                    type: OrganizationEmptyStateType.noResults,
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    isCompact: true,
                  )
                : OrganizationEmptyView(
                    type: OrganizationEmptyStateType.noAuthorizedOrganizations,
                    onAction: _handleEmptyAction,
                    isCompact: true,
                  )
          else
            Flexible(
              child: RadioGroup<String>(
                groupValue: items.where((o) => o.isCurrent).map((o) => o.id).firstOrNull,
                onChanged: (selectedId) {
                  if (selectedId == null) return;
                  final org = items.where((o) => o.id == selectedId).firstOrNull;
                  if (org != null && !org.isCurrent) {
                    _handleSelectOrganization(org);
                  }
                },
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const VGap.sm(),
                  itemBuilder: (context, index) {
                    final org = items[index];
                    return _buildOrganizationCard(colors, org);
                  },
                ),
              ),
            ),
          const VGap.lg(),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(
    dynamic colors,
    AccessibleTenant org,
  ) {
    final isCurrent = org.isCurrent;
    final canTap = !isCurrent;
    final muted = !canTap && !isCurrent;

    final Color iconColor = isCurrent
        ? colors.success
        : muted
        ? colors.disabledFg
        : colors.textSecondary;

    final Color titleColor = muted ? colors.disabledFg : colors.textPrimary;

    final Color subtitleColor = muted ? colors.disabledFg : colors.textSecondary;

    final String displayRole = IamRoleLabelMapper.toDisplayLabel(org.roleCode);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      tone: isCurrent ? VComponentTone.success : null,
      enabled: canTap || isCurrent,
      onTap: canTap ? () => _handleSelectOrganization(org) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent ? colors.successBg : colors.surfaceAlt,
              borderRadius: BorderRadius.circular(VRadius.card),
            ),
            child: Center(
              child: VIcon(
                icon: isCurrent ? VIcons.store : VIcons.person,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  org.name,
                  variant: VTextVariant.bodyDefault,
                  color: titleColor,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  '${org.code} · $displayRole',
                  variant: VTextVariant.bodySmall,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VRadio<String>(
            value: org.id,
            enabled: canTap || isCurrent,
            onChanged: canTap ? (_) => _handleSelectOrganization(org) : null,
          ),
        ],
      ),
    );
  }
}

/// Helper function mở VBottomSheet Chọn tổ chức.
///
/// [onConfirmSwitch] replaces the fake delay on the production path — ERP
/// wires this to `SessionController.switchTo`. Returns `true` on success.
Future<AccessibleTenant?> showSelectOrganizationBottomSheet({
  required BuildContext context,
  List<AccessibleTenant>? organizations,
  ValueChanged<AccessibleTenant>? onOrganizationSelected,
  Future<bool> Function(AccessibleTenant org)? onConfirmSwitch,
  OrganizationEmptyStateType? emptyStateType,
  VoidCallback? onEmptyAction,
  Future<List<AccessibleTenant>?> Function()? onRetryLoad,
}) async {
  final selectedOrg = await showVAdaptiveSheet<AccessibleTenant>(
    context: context,
    child: SelectOrganizationBottomSheet(
      organizations: organizations ?? const [],
      emptyStateType: emptyStateType,
      onEmptyAction: onEmptyAction,
      onRetryLoad: onRetryLoad,
    ),
  );

  if (selectedOrg == null || !context.mounted) return null;

  final confirmed = await showConfirmSwitchOrganizationBottomSheet(
    context: context,
    targetOrganizationName: selectedOrg.name,
  );

  if (!context.mounted) return null;

  if (confirmed == true) {
    VLoading.show(
      context: context,
      title: 'Đang chuyển tổ chức',
      description: 'Đang tải dữ liệu và quyền truy cập của ${selectedOrg.name}.',
    );

    var success = true;
    Object? switchError;
    try {
      if (onConfirmSwitch != null) {
        success = await onConfirmSwitch(selectedOrg);
      }
    } catch (e) {
      success = false;
      switchError = e;
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return null;

    if (success) {
      onOrganizationSelected?.call(selectedOrg);
      VToast.show(
        context,
        title: 'Thành công',
        message: 'Đã chuyển sang ${selectedOrg.name}.',
        type: VToastType.success,
      );
      return selectedOrg;
    }

    final message = switchError?.toString() ?? 'Không thể chuyển sang ${selectedOrg.name}.';
    VToast.show(
      context,
      title: 'Không thành công',
      message: message,
      type: VToastType.danger,
    );
    return null;
  } else if (confirmed == false) {
    return showSelectOrganizationBottomSheet(
      context: context,
      organizations: organizations,
      onOrganizationSelected: onOrganizationSelected,
      onConfirmSwitch: onConfirmSwitch,
      emptyStateType: emptyStateType,
      onEmptyAction: onEmptyAction,
      onRetryLoad: onRetryLoad,
    );
  }

  return null;
}
