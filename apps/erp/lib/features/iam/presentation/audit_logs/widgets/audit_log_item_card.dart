import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../../data/models/tenant_audit_log.dart';
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
    final ict = VDateTime.toIct(dt);
    final day = ict.day.toString().padLeft(2, '0');
    final month = ict.month.toString().padLeft(2, '0');
    final year = ict.year;
    final hour = ict.hour.toString().padLeft(2, '0');
    final minute = ict.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isLegacy =
        log.actorDisplayOrigin == TenantAuditDisplayOrigin.current ||
        log.subjectDisplayOrigin == TenantAuditDisplayOrigin.current;
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
            size: 20,
            color: iconColor,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: VText(
                        log.title,
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (isLegacy) ...[
                      const SizedBox(width: VSpacing.space2),
                      const VBadge(
                        label: 'Thông tin hiện tại',
                        tone: VComponentTone.neutral,
                        variant: VBadgeVariant.soft,
                        isSmall: true,
                      ),
                    ],
                  ],
                ),
                const VGap.xs(),
                VText(
                  log.actorRole.isNotEmpty && log.actorRole != '—'
                      ? '${log.actorName} (${log.actorRole}) · ${_formatTimestamp(log.timestamp)}'
                      : '${log.actorName} · ${_formatTimestamp(log.timestamp)}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                if (log.targetOrg.isNotEmpty && log.targetOrg != '—') ...[
                  const VGap.xs(),
                  VText(
                    '${log.targetSubjectLabel ?? 'Đối tượng'}: ${log.targetOrg}',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
