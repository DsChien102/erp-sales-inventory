import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/user_ui_model.dart';
import 'role_radio_list.dart';

class SelectRoleWide extends StatelessWidget {
  const SelectRoleWide({
    super.key,
    required this.member,
    required this.roles,
    required this.selectedRoleCode,
    required this.onChanged,
  });

  final MemberUiModel member;
  final List<RoleChoice> roles;
  final String? selectedRoleCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = member.status == MemberStatus.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RadioGroup<String>(
            groupValue: selectedRoleCode,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VCard(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: VText(
                                member.name,
                                variant: VTextVariant.headingH4,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          VBadge(
                            label: isActive ? 'Hoạt động' : 'Tạm ngừng',
                            tone: isActive
                                ? VComponentTone.success
                                : VComponentTone.danger,
                            variant: VBadgeVariant.soft,
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
                            : 'Quyền sở hữu: Thành viên',
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const VGap.md(),
                Semantics(
                  header: true,
                  child: const VText(
                    'Chọn vai trò mới',
                    variant: VTextVariant.headingH4,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const VGap.xs(),
                VText(
                  'Mỗi thành viên có đúng một vai trò hiện hành.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                for (final role in roles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.space3),
                    child: InkWell(
                      onTap: role.isCurrent
                          ? null
                          : () => onChanged(role.id),
                      borderRadius: BorderRadius.circular(VRadius.card),
                      child: Container(
                        padding: EdgeInsets.all(
                          role.id == selectedRoleCode ? 15.5 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: role.id == selectedRoleCode
                              ? colors.surfaceBrand
                              : colors.surface,
                          border: Border.all(
                            color: role.id == selectedRoleCode
                                ? colors.primary
                                : colors.borderDefault,
                            width: role.id == selectedRoleCode ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(VRadius.card),
                        ),
                        child: Row(
                          children: [
                            VIcon(
                              icon: VIcons.person,
                              size: 24,
                              color: role.id == selectedRoleCode
                                  ? colors.primary
                                  : colors.textPrimary,
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
                                      color: role.id == selectedRoleCode
                                          ? colors.primary
                                          : colors.textPrimary,
                                    ),
                                  ),
                                  if (role.description.isNotEmpty) ...[
                                    const VGap.xs(),
                                    VText(
                                      role.description,
                                      variant: VTextVariant.bodySmall,
                                      color: colors.textSecondary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (role.isCurrent)
                              const VBadge(
                                label: 'Hiện tại',
                                tone: VComponentTone.success,
                                variant: VBadgeVariant.soft,
                                isSmall: true,
                              )
                            else
                              Radio<String>(
                                value: role.id,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
