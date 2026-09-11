import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Card hiển thị thông tin Chủ sở hữu tổ chức.
class OrganizationDetailOwnerCard extends StatelessWidget {
  final OrganizationUiModel organization;

  const OrganizationDetailOwnerCard({
    super.key,
    required this.organization,
  });

  String _getOwnerInitials(String ownerName) {
    final words = ownerName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, words[0].length.clamp(1, 2)).toUpperCase();
    }
    return 'SH';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final ownerName = organization.ownerName ?? 'Chưa xác định';
    final ownerEmail = organization.ownerEmail ?? '';

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Chủ sở hữu',
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),
          Row(
            children: [
              // Owner Avatar Initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r12),
                ),
                alignment: Alignment.center,
                child: VText(
                  _getOwnerInitials(ownerName),
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const VGap.horizontalMd(),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      ownerName,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ownerEmail.isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        ownerEmail,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Owner Role Tag
              VText(
                organization.ownerRole.toLowerCase() == 'owner' || organization.ownerRole.isEmpty
                    ? 'Chủ sở hữu'
                    : organization.ownerRole,
                style: VTypography.bodySmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
