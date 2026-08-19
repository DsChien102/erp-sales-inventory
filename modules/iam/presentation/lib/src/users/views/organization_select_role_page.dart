import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';
import '../invitation_role_options.dart';

class RoleOptionItem {
  final String title;
  final String description;
  final String roleCode;

  const RoleOptionItem({
    required this.title,
    required this.description,
    required this.roleCode,
  });

  factory RoleOptionItem.fromInvitationOption(InvitationRoleOption option) {
    return RoleOptionItem(
      title: option.label,
      description: 'Vai trò được gán khi tham gia',
      roleCode: option.roleId,
    );
  }
}

/// Màn hình Chọn vai trò (TA-D-03).
class OrganizationSelectRolePage extends StatefulWidget {
  final MemberUiModel member;
  final List<InvitationRoleOption>? invitationRoleOptions;

  const OrganizationSelectRolePage({
    super.key,
    required this.member,
    this.invitationRoleOptions,
  });

  @override
  State<OrganizationSelectRolePage> createState() => _OrganizationSelectRolePageState();
}

class _OrganizationSelectRolePageState extends State<OrganizationSelectRolePage> {
  String? _selectedRole;

  static const List<RoleOptionItem> _availableRoles = [
    RoleOptionItem(
      title: 'Nhân viên bán hàng',
      description: 'Bán hàng và chăm sóc khách hàng',
      roleCode: 'staff',
    ),
    RoleOptionItem(
      title: 'Kế toán',
      description: 'Công nợ, hóa đơn và báo cáo',
      roleCode: 'accountant',
    ),
    RoleOptionItem(
      title: 'Thủ kho',
      description: 'Nhập xuất, tồn kho và kiểm kê',
      roleCode: 'warehouse',
    ),
    RoleOptionItem(
      title: 'Chủ cửa hàng',
      description: 'Quản lý toàn bộ cửa hàng',
      roleCode: 'store_owner',
    ),
  ];

  List<RoleOptionItem> get _orderedRoles {
    final fromInvite = widget.invitationRoleOptions;
    if (fromInvite != null && fromInvite.isNotEmpty) {
      return fromInvite.map(RoleOptionItem.fromInvitationOption).toList(growable: false);
    }

    final currentRoleTitle = widget.member.role;
    final index = _availableRoles.indexWhere((r) => r.title == currentRoleTitle);

    if (index <= 0) return _availableRoles;

    final result = List<RoleOptionItem>.from(_availableRoles);
    final currentItem = result.removeAt(index);
    result.insert(0, currentItem);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final member = widget.member;
    final isActive = member.status == MemberStatus.active;

    return VPageScaffold(
      title: 'Chọn vai trò',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.secondary,
                tone: VComponentTone.neutral,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: VButton(
                label: 'Tiếp tục',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        final selectedOption = _orderedRoles.firstWhere(
                          (r) => r.title == _selectedRole,
                          orElse: () => _orderedRoles.first,
                        );
                        Navigator.of(context).pop(selectedOption.roleCode);
                      },
              ),
            ),
          ],
        ),
      ),
      body: RadioGroup<String>(
        groupValue: _selectedRole,
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedRole = val;
            });
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            // Top Summary Card
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: VText(
                          member.name,
                          variant: VTextVariant.headingH4,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      VBadge(
                        label: isActive ? 'Hoạt động' : 'Tạm ngừng',
                        status: isActive ? VBadgeStatus.success : VBadgeStatus.danger,
                        isSmall: true,
                      ),
                    ],
                  ),
                  const VGap.xs(),
                  VText(
                    '${member.email} · ${member.role}',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.md(),
                  VText(
                    member.isOwner
                        ? 'Quyền sở hữu: Chủ sở hữu'
                        : 'Danh tính: ${member.identityText}',
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const VGap.md(),

            // Section Title
            VText(
              'Chọn vai trò mới',
              variant: VTextVariant.headingH4,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.xs(),
            VText(
              'Mỗi thành viên có đúng một vai trò hiện hành.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.md(),

            // Role List
            ..._orderedRoles.map((role) {
              final isCurrent = role.title == member.role;
              final isSelected = role.title == _selectedRole;

              return Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.space3),
                child: InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          setState(() {
                            _selectedRole = role.title;
                          });
                        },
                  borderRadius: BorderRadius.circular(VRadius.card),
                  child: Container(
                    padding: const EdgeInsets.all(VSpacing.space4),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.successBg : colors.surface,
                      border: Border.all(
                        color: isSelected ? colors.success : colors.borderDefault,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(VRadius.card),
                    ),
                    child: Row(
                      children: [
                        VIcon(
                          icon: VIcons.person,
                          size: 24,
                          color: isSelected ? colors.success : colors.textPrimary,
                        ),
                        const VGap.horizontalMd(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VText(
                                role.title,
                                variant: VTextVariant.bodyDefault,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? colors.success : colors.textPrimary,
                                ),
                              ),
                              const VGap.xs(),
                              VText(
                                role.description,
                                variant: VTextVariant.bodySmall,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          const VBadge(
                            label: 'Hiện tại',
                            status: VBadgeStatus.success,
                            isSmall: true,
                          )
                        else
                          IgnorePointer(
                            child: VRadio<String>(
                              value: role.title,
                              tone: VComponentTone.success,
                              onChanged: null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
