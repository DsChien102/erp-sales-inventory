import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';
import '../models/platform_tenant_ui.dart';

/// Thẻ "Thành viên tổ chức" ở C2 (chỉ đọc).
class PlatformOrganizationMembersCard extends StatelessWidget {
  const PlatformOrganizationMembersCard({super.key, required this.members});

  final List<PlatformTenantMember> members;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                'Thành viên tổ chức',
                style: VTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              VText(
                '${members.length} thành viên',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
          const VGap.md(),
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0) const VGap.sm(),
            _MemberRow(member: members[i]),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final PlatformTenantMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          VIcon(icon: VIcons.person, size: 20, color: colors.textPrimary),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  member.displayName,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.xs(),
                VText(
                  member.roleDisplay,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
