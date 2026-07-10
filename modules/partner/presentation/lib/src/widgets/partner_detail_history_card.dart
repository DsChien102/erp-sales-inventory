import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';
import 'partner_detail_section.dart';

/// Card «Lịch sử gần đây» — preview ngắn; chi tiết đầy đủ ở SG-06.
class PartnerDetailHistoryCard extends StatelessWidget {
  const PartnerDetailHistoryCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final createdDate = PartnerDetailFormatters.createdDateLabel(dto);
    final hasPreview = createdDate != null;
    final countLabel = hasPreview ? '1' : null;

    return PartnerDetailExpandableCard(
      title: 'Lịch sử gần đây',
      icon: Icons.history_toggle_off_rounded,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: countLabel == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countLabel,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      child: hasPreview
          ? PartnerDetailActivityRow(
              dateLabel: createdDate,
              activityText: PartnerDetailFormatters.createdActivityText(dto),
            )
          : Text(
              'Chưa có lịch sử giao dịch.',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
    );
  }
}
