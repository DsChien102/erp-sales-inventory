import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../data/models/tenant_audit_log.dart';
import '../models/audit_log_ui_model.dart';
import 'detail_part.dart';

/// Nhóm các dòng lịch sử theo ngày Việt Nam (iPhone).
class AuditDaySection extends StatelessWidget {
  const AuditDaySection({
    super.key,
    required this.dayLabel,
    required this.items,
    required this.onTap,
  });

  final String dayLabel;
  final List<AuditLogItemUiModel> items;
  final ValueChanged<AuditLogItemUiModel> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Semantics(
            header: true,
            child: Text(
              dayLabel,
              style: VTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        VCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.borderDefault),
                _AuditDayRow(
                  log: items[i],
                  onTap: () => onTap(items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditDayRow extends StatelessWidget {
  const _AuditDayRow({
    required this.log,
    required this.onTap,
  });

  final AuditLogItemUiModel log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final resultBadge = auditNonSuccessBadge(log.status);
    final isLegacy = log.subjectDisplayOrigin == TenantAuditDisplayOrigin.current;
    final subjectType = log.targetSubjectLabel ?? 'Đối tượng';
    final subjectName = log.subjectName.isEmpty ? log.targetOrg : log.subjectName;

    return InkWell(
      onTap: onTap,
      hoverColor: colors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Giờ bám đỉnh dòng (proto `.t1-aday__time { align-self: flex-start; line-height: 22px }`), mũi tên giữa.
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 40,
                child: Text(
                  formatAuditTimeOnly(log.timestamp),
                  style: VTypography.bodySmall.copyWith(
                    height: 22 / 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      VText(
                        log.title,
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      ?resultBadge,
                      if (isLegacy)
                        const VBadge(
                          label: 'Thông tin hiện tại',
                          tone: VComponentTone.neutral,
                          variant: VBadgeVariant.soft,
                          isSmall: true,
                        ),
                    ],
                  ),
                  VText(
                    formatAuditActorSummary(log),
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  VText(
                    '$subjectType: $subjectName',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: VIcon(
                icon: VIcons.chevronRight,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
