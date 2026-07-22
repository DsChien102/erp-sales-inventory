import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';

/// Card hiển thị từng nhật ký thao tác trong danh sách (PA-D-02).
class AuditLogItemCard extends StatelessWidget {
  final AuditLogItemUiModel log;
  final VoidCallback? onTap;

  const AuditLogItemCard({
    super.key,
    required this.log,
    this.onTap,
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
    final Color iconColor = log.icon == VIcons.info ? colors.info : colors.textPrimary;

    return VCard(
      onTap: onTap,
      backgroundColor: colors.surface,
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(
            icon: log.icon,
            size: 24,
            color: iconColor,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  log.title,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.xs(),
                VText(
                  '${log.actorName} · ${_formatTimestamp(log.timestamp)}',
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
