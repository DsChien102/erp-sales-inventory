import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'confirm_switch_organization_bottom_sheet.dart';
import 'organization_empty_view.dart';

/// Item mô hình đại diện cho một tổ chức trong VBottomSheet Chọn tổ chức.
class SelectOrganizationItemUiModel {
  final String id;
  final String name;
  final String code;
  final String roleLabel;
  final bool isCurrent;
  final bool isSuspended;

  const SelectOrganizationItemUiModel({
    required this.id,
    required this.name,
    required this.code,
    required this.roleLabel,
    this.isCurrent = false,
    this.isSuspended = false,
  });

  static const List<SelectOrganizationItemUiModel> defaultOrganizations = [
    SelectOrganizationItemUiModel(
      id: 'org-01',
      name: 'Thú y Minh Phát',
      code: 'TEN-000138',
      roleLabel: 'Chủ cửa hàng',
      isCurrent: true,
    ),
    SelectOrganizationItemUiModel(
      id: 'org-02',
      name: 'Phòng khám Minh Tâm',
      code: 'TEN-000204',
      roleLabel: 'Kế toán',
      isCurrent: false,
    ),
    SelectOrganizationItemUiModel(
      id: 'org-03',
      name: 'ASC Commerce',
      code: 'TEN-000095',
      roleLabel: 'Nhân viên bán hàng',
      isCurrent: false,
      isSuspended: true,
    ),
  ];
}

/// VBottomSheet Chọn tổ chức (TA-O-01 — Chọn tổ chức).
class SelectOrganizationBottomSheet extends StatefulWidget {
  final List<SelectOrganizationItemUiModel> organizations;
  final ValueChanged<SelectOrganizationItemUiModel>? onOrganizationSelected;
  final OrganizationEmptyStateType? emptyStateType;
  final String? suspendedOrgName;
  final VoidCallback? onEmptyAction;

  const SelectOrganizationBottomSheet({
    super.key,
    this.organizations = SelectOrganizationItemUiModel.defaultOrganizations,
    this.onOrganizationSelected,
    this.emptyStateType,
    this.suspendedOrgName,
    this.onEmptyAction,
  });

  @override
  State<SelectOrganizationBottomSheet> createState() =>
      _SelectOrganizationBottomSheetState();
}

class _SelectOrganizationBottomSheetState
    extends State<SelectOrganizationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SelectOrganizationItemUiModel> get _filteredOrganizations {
    if (_searchQuery.isEmpty) return widget.organizations;
    return widget.organizations.where((org) {
      return org.name.toLowerCase().contains(_searchQuery) ||
          org.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _handleSelectOrganization(SelectOrganizationItemUiModel org) {
    if (org.isCurrent || org.isSuspended) return;
    widget.onOrganizationSelected?.call(org);
    Navigator.of(context).pop(org);
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
          VText(
            'Chọn tổ chức',
            variant: VTextVariant.headingH3,
            style: const TextStyle(fontWeight: FontWeight.w700),
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
          if (widget.emptyStateType != null)
            OrganizationEmptyView(
              type: widget.emptyStateType!,
              suspendedOrgName: widget.suspendedOrgName,
              onAction: widget.onEmptyAction ?? () {},
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
                    onAction: widget.onEmptyAction ?? () {},
                    isCompact: true,
                  )
          else
            Flexible(
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
          const VGap.lg(),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(
    dynamic colors,
    SelectOrganizationItemUiModel org,
  ) {
    final isCurrent = org.isCurrent;
    final isSuspended = org.isSuspended;

    final Color bgColor = isCurrent
        ? colors.successBg
        : colors.surface;

    final Border border = isCurrent
        ? Border.all(color: colors.success, width: 1.5)
        : Border.all(color: colors.borderDefault);

    final Color iconColor = isCurrent
        ? colors.success
        : isSuspended
            ? colors.disabledFg
            : colors.textSecondary;

    final Color titleColor = isSuspended
        ? colors.disabledFg
        : colors.textPrimary;

    final Color subtitleColor = isSuspended
        ? colors.disabledFg
        : colors.textSecondary;

    final String statusSuffix = isCurrent
        ? ' · Hiện tại'
        : isSuspended
            ? ' · Tạm ngừng'
            : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isCurrent || isSuspended)
            ? null
            : () => _handleSelectOrganization(org),
        borderRadius: BorderRadius.circular(VRadius.card),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            borderRadius: BorderRadius.circular(VRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colors.success.withValues(alpha: 0.1)
                      : colors.surfaceAlt,
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
                      '${org.code} · ${org.roleLabel}$statusSuffix',
                      variant: VTextVariant.bodySmall,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
              const VGap.horizontalSm(),
              _buildRadioIndicator(colors, isCurrent: isCurrent, isSuspended: isSuspended),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioIndicator(
    dynamic colors, {
    required bool isCurrent,
    required bool isSuspended,
  }) {
    if (isCurrent) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colors.success,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSuspended ? colors.borderDefault : colors.borderDefault,
          width: 1.5,
        ),
      ),
    );
  }
}

/// Helper function mở VBottomSheet Chọn tổ chức.
Future<SelectOrganizationItemUiModel?> showSelectOrganizationBottomSheet({
  required BuildContext context,
  List<SelectOrganizationItemUiModel>? organizations,
  ValueChanged<SelectOrganizationItemUiModel>? onOrganizationSelected,
  OrganizationEmptyStateType? emptyStateType,
  String? suspendedOrgName,
  VoidCallback? onEmptyAction,
}) async {
  final selectedOrg = await showVBottomSheet<SelectOrganizationItemUiModel>(
    context: context,
    child: SelectOrganizationBottomSheet(
      organizations:
          organizations ?? SelectOrganizationItemUiModel.defaultOrganizations,
      emptyStateType: emptyStateType,
      suspendedOrgName: suspendedOrgName,
      onEmptyAction: onEmptyAction,
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

    await Future.delayed(const Duration(milliseconds: 1000));

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (context.mounted) {
      onOrganizationSelected?.call(selectedOrg);
      VToast.show(
        context,
        title: 'Thành công',
        message: 'Đã chuyển sang ${selectedOrg.name}.',
        type: VToastType.success,
      );
    }
    return selectedOrg;
  } else if (confirmed == false) {
    // Nếu người dùng chọn "Quay lại", mở lại sheet chọn tổ chức
    return showSelectOrganizationBottomSheet(
      context: context,
      organizations: organizations,
      onOrganizationSelected: onOrganizationSelected,
      emptyStateType: emptyStateType,
      suspendedOrgName: suspendedOrgName,
      onEmptyAction: onEmptyAction,
    );
  }

  return null;
}
