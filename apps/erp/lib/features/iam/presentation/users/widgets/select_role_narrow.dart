import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../models/user_ui_model.dart';
import 'role_radio_list.dart';
import 'user_list_card.dart';

class SelectRoleNarrow extends StatelessWidget {
  const SelectRoleNarrow({
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

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        DetailHeaderNarrow(
          leading: DetailAvatar(
            userInitial(member.name),
            size: 52,
            muted: !isActive,
          ),
          title: member.name,
          subtitle: '${member.email} · ${member.role}\n${member.isOwner ? 'Quyền sở hữu: Chủ sở hữu' : 'Quyền sở hữu: Thành viên'}',
          badge: VBadge(
            label: isActive ? 'Hoạt động' : 'Tạm ngừng',
            tone: isActive ? VComponentTone.success : VComponentTone.danger,
            variant: VBadgeVariant.soft,
            isSmall: true,
          ),
          badgeInline: true,
        ),
        const SizedBox(height: VSpacing.space3),
        Semantics(
          header: true,
          child: VText(
            'Chọn vai trò mới',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        VText(
          'Mỗi thành viên có đúng một vai trò hiện hành.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
        RoleRadioList(
          roles: roles,
          value: selectedRoleCode,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
