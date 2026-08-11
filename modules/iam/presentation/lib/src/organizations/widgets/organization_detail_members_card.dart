import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Card hiển thị danh sách "Thành viên tổ chức" (trạng thái Đang hoạt động PA-D-03).
class OrganizationDetailMembersCard extends StatelessWidget {
  final OrganizationUiModel organization;
  final ValueChanged<OrganizationMemberUiModel>? onMemberTap;

  const OrganizationDetailMembersCard({
    super.key,
    required this.organization,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final members = organization.members;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Member Count
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
                '${organization.memberCount} thành viên',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
          const VGap.md(),

          // Member List Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const VGap.sm(),
            itemBuilder: (context, index) {
              final member = members[index];
              return Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VRadius.card),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onMemberTap?.call(member),
                    borderRadius: BorderRadius.circular(VRadius.card),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.space3,
                        vertical: VSpacing.space3,
                      ),
                      child: Row(
                        children: [
                          // Person Icon Box
                          VIcon(
                            icon: VIcons.person,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          const VGap.horizontalMd(),

                          // Name & Role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VText(
                                  member.name,
                                  style: VTypography.bodyDefault.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const VGap.xs(),
                                VText(
                                  member.role,
                                  variant: VTextVariant.bodySmall,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),

                          // Chevron Right
                          VIcon(
                            icon: VIcons.chevronRight,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
