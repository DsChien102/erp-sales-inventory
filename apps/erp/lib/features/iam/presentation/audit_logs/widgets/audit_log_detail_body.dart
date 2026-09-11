import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../models/audit_log_ui_model.dart';
import 'audit_detail_row.dart';
import 'audit_log_change_diff_item.dart';

/// Success body for [AuditLogDetailPage] — cards + tracking copy.
class AuditLogDetailBody extends StatelessWidget {
  const AuditLogDetailBody({
    super.key,
    required this.log,
    this.onBackPressed,
  });

  final AuditLogItemUiModel log;
  final VoidCallback? onBackPressed;

  static String formatTimestamp(DateTime dt) {
    final ict = VDateTime.toIct(dt);
    final day = ict.day.toString().padLeft(2, '0');
    final month = ict.month.toString().padLeft(2, '0');
    final year = ict.year;
    final hour = ict.hour.toString().padLeft(2, '0');
    final minute = ict.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  static String formatTraceId(String value) {
    if (value.length <= 24) return value;
    return '${value.substring(0, 12)}…${value.substring(value.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    Color badgeBg;
    Color badgeFg;
    if (log.status == AuditLogStatus.success) {
      badgeBg = colors.successBg;
      badgeFg = colors.success;
    } else if (log.status == AuditLogStatus.blocked) {
      badgeBg = colors.warningBg;
      badgeFg = colors.warning;
    } else {
      badgeBg = colors.dangerBg;
      badgeFg = colors.danger;
    }

    final subjectLabel = log.targetSubjectLabel ?? 'Đối tượng';
    final detailLabel = log.targetDetailLabel ?? 'Mã đối tượng';
    final detailValue = log.targetDetailValue ?? '—';

    final isActorLegacy = log.actorDisplayOrigin == TenantAuditDisplayOrigin.current;
    final isSubjectLegacy = log.subjectDisplayOrigin == TenantAuditDisplayOrigin.current;

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: VIcon(
            icon: VIcons.chevronLeft,
            color: colors.textPrimary,
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const VText(
          'Chi tiết hoạt động',
          variant: VTextVariant.headingH4,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: VIcon(
                      icon: log.icon,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.horizontalSm(),
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
                          log.actionCode,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.space3,
                      vertical: VSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: VText(
                      log.statusLabel,
                      variant: VTextVariant.bodySmall,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VGap.md(),
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VText(
                        'Ngữ cảnh',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (log.isActorUnavailable)
                        const VBadge(
                          label: 'Không còn dữ liệu',
                          status: VBadgeStatus.warning,
                          isSmall: true,
                        )
                      else if (isActorLegacy)
                        const VBadge(
                          label: 'Thông tin hiện tại',
                          status: VBadgeStatus.draft,
                          isSmall: true,
                        ),
                    ],
                  ),
                  const VGap.md(),
                  AuditDetailRow(
                    label: 'Người thực hiện',
                    value: log.actorName,
                  ),
                  const VGap.sm(),
                  AuditDetailRow(
                    label: 'Loại chủ thể',
                    value: log.actorRole,
                  ),
                ],
              ),
            ),
            const VGap.md(),
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VText(
                        'Đối tượng',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (log.subjectDisplayOrigin == TenantAuditDisplayOrigin.unavailable)
                        const VBadge(
                          label: 'Không còn dữ liệu',
                          status: VBadgeStatus.warning,
                          isSmall: true,
                        )
                      else if (isSubjectLegacy)
                        const VBadge(
                          label: 'Thông tin hiện tại',
                          status: VBadgeStatus.draft,
                          isSmall: true,
                        ),
                    ],
                  ),
                  const VGap.md(),
                  AuditDetailRow(
                    label: subjectLabel,
                    value: log.subjectName.isEmpty ? log.targetOrg : log.subjectName,
                  ),
                  if (detailValue != '—' || log.subjectCode.isNotEmpty) ...[
                    const VGap.sm(),
                    AuditDetailRow(
                      label: detailLabel,
                      value: detailValue != '—' ? detailValue : log.subjectCode,
                    ),
                  ],
                ],
              ),
            ),
            const VGap.md(),
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Thông tin truy vết',
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  AuditDetailRow(
                    label: 'Thời điểm',
                    value: formatTimestamp(log.timestamp),
                  ),
                  const VGap.sm(),
                  AuditDetailRow(label: 'Nguồn', value: log.sourceApp),
                  if (log.auditDisplayId != null) ...[
                    const VGap.sm(),
                    AuditDetailRow(
                      label: 'Audit ID',
                      value: log.auditDisplayId!,
                    ),
                  ],
                  const VGap.sm(),
                  AuditDetailRow(
                    label: 'Mã theo dõi',
                    value: formatTraceId(log.correlationId),
                    copyable: true,
                    copyValue: log.correlationId,
                    copyTooltip: 'Sao chép mã theo dõi',
                  ),
                ],
              ),
            ),
            const VGap.md(),
            if (log.isActorUnavailable) ...[
              VCard(
                backgroundColor: colors.warningBg,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VText(
                      'Không còn thông tin người thực hiện',
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.warning,
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      'Thông tin người thực hiện không còn khả dụng tại thời điểm xem.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const VGap.md(),
            ],
            if (log.changes.isNotEmpty) ...[
              VCard(
                backgroundColor: colors.surfaceAlt,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: log.changes.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
                    child: Divider(height: 1, color: colors.borderDefault),
                  ),
                  itemBuilder: (context, index) {
                    return AuditLogChangeDiffItem(
                      change: log.changes[index],
                      embedded: true,
                    );
                  },
                ),
              ),
            ] else if (log.beforeRedacted || log.afterRedacted) ...[
              Container(
                padding: const EdgeInsets.all(VSpacing.space4),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      subjectLabel,
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      'Trước: ${log.beforeRedacted ? '[Đã che theo chính sách]' : '—'}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: 2),
                    VText(
                      'Sau: ${log.afterRedacted ? '[Đã che theo chính sách]' : '—'}',
                      variant: VTextVariant.bodySmall,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      'Dữ liệu nhạy cảm đã được che theo chính sách.',
                      variant: VTextVariant.caption,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
            const VGap.xl(),
          ],
        ),
      ),
    );
  }
}
