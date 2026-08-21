import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

class PartnerChangeHistoryCard extends StatelessWidget {
  const PartnerChangeHistoryCard({
    super.key,
    required this.entry,
  });

  final PartnerChangeHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final reason = entry.reason?.trim() ?? '';
    final showFieldLabels = entry.changes.length > 1;

    return VCard(
      key: Key('partner_change_history_entry_${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VText(
                  entry.summary,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const VGap.horizontalSm(),
              VText(
                _formatDateTime(entry.occurredAt),
                variant: VTextVariant.caption,
                color: colors.textSecondary,
              ),
            ],
          ),
          if (entry.changes.isNotEmpty) ...[
            const VGap.sm(),
            for (var index = 0; index < entry.changes.length; index++) ...[
              VText(
                _changeDescription(
                  entry.changes[index],
                  showFieldLabel: showFieldLabels,
                ),
                key: Key('partner_change_${entry.id}_$index'),
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              if (index < entry.changes.length - 1) const VGap.xs(),
            ],
          ],
          if (reason.isNotEmpty) ...[
            const VGap.xs(),
            VText(
              'Lý do: $reason',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const VGap.xs(),
          VText(
            'bởi ${entry.actorDisplayName}',
            variant: VTextVariant.caption,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  static String _changeDescription(
    PartnerFieldChange change, {
    required bool showFieldLabel,
  }) {
    final prefix = showFieldLabel ? '${change.label}: ' : '';
    return switch (change.kind) {
      PartnerFieldChangeKind.added => '${prefix}Thêm mới: ${change.after}',
      PartnerFieldChangeKind.removed => '$prefixĐã xóa: ${change.before}',
      PartnerFieldChangeKind.modified => '$prefix${change.before} → ${change.after}',
    };
  }

  static String _formatDateTime(DateTime occurredAt) {
    final ict = VDateTime.toIct(occurredAt);
    final year = ict.year.toString().padLeft(4, '0');
    final month = ict.month.toString().padLeft(2, '0');
    final day = ict.day.toString().padLeft(2, '0');
    final hour = ict.hour.toString().padLeft(2, '0');
    final minute = ict.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
