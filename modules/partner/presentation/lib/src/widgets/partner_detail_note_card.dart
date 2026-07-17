import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';

/// Card «Ghi chú» — nội dung ghi chú nội bộ; tap header để mở/đóng.
class PartnerDetailNoteCard extends StatelessWidget {
  const PartnerDetailNoteCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final note = PartnerDetailFormatters.note(dto)?.trim() ?? '';
    final isEmpty = note.isEmpty;

    return PartnerDetailExpandableCard(
      key: const Key('partner_detail_note_card'),
      title: 'Ghi chú',
      icon: VIcons.stickyNote,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Chưa có',
                style: VTypography.bodySmall.copyWith(
                  color: colors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      child: Text(
        isEmpty ? '—' : note,
        style: VTypography.bodyDefault.copyWith(
          color: isEmpty ? colors.textMuted : colors.textPrimary,
          fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
        ),
      ),
    );
  }
}
