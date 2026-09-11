import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_detail_formatters.dart';

class PartnerDetailSummaryCard extends StatelessWidget {
  const PartnerDetailSummaryCard({super.key, required this.detail});

  final PartnerDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final roleLabel = PartnerDetailFormatters.roleBadgeLabel(detail.roles);
    final taxCode = PartnerDetailFormatters.taxCode(detail);
    final icon = detail.partnerType == PartnerType.person
        ? VIcons.person
        : VIcons.apartment;
    final hasTaxCode = taxCode != null && taxCode.isNotEmpty;

    return VCard(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space2 + 2,
      ),
      child: Row(
        children: [
          VIconBox(
            icon: icon,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.surfaceBrand,
            iconColor: colors.primary,
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  detail.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (hasTaxCode) ...[
                  const VGap.xs(),
                  VText(
                    'MST: $taxCode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          if (roleLabel.isNotEmpty) ...[
            const SizedBox(width: VSpacing.space2),
            VBadge(
              label: roleLabel,
              status: VBadgeStatus.success,
              isSmall: true,
            ),
          ],
        ],
      ),
    );
  }
}
