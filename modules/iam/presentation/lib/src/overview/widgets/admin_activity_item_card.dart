import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/admin_overview_ui_model.dart';

/// Card hiển thị từng hoạt động đặc quyền gần đây.
class AdminActivityItemCard extends StatelessWidget {
  final AdminActivityItemUiModel activity;

  const AdminActivityItemCard({
    super.key,
    required this.activity,
  });

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      backgroundColor: colors.surface,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(
            icon: activity.icon,
            size: 24,
            color: activity.icon == VIcons.info ? colors.info : colors.textPrimary,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  activity.title,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.xs(),
                VText(
                  '${activity.actorName} · ${_formatTimestamp(activity.timestamp)}',
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
