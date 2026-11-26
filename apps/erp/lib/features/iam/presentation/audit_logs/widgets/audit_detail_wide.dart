import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../data/models/tenant_audit_log.dart';
import '../../shared/detail_layout.dart';
import '../models/audit_log_ui_model.dart';
import 'audit_detail_row.dart';
import 'detail_part.dart';

/// Thân trang chi tiết hoạt động trên màn hình rộng (cột 720).
class AuditDetailWide extends StatelessWidget {
  const AuditDetailWide({super.key, required this.log});

  final AuditLogItemUiModel log;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final subjectLabel = log.targetSubjectLabel ?? 'Đối tượng';
    final detailLabel = log.targetDetailLabel ?? 'Mã đối tượng';
    final detailValue = log.targetDetailValue ?? '—';
    final isActorLegacy = log.actorDisplayOrigin == TenantAuditDisplayOrigin.current;
    final isSubjectLegacy =
        log.subjectDisplayOrigin == TenantAuditDisplayOrigin.current;
    final hasRawStates = log.beforeRedacted ||
        log.afterRedacted ||
        log.beforeState.isNotEmpty ||
        log.afterState.isNotEmpty;

    final parts = <Widget>[
      if (log.changes.isNotEmpty || hasRawStates)
        DetailPart(
          title: 'Dữ liệu thay đổi',
          padding: const EdgeInsets.all(20),
          wideHeader: true,
          children: [
            if (log.changes.isNotEmpty)
              for (final change in log.changes)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      change.fieldLabel,
                      variant: VTextVariant.bodySmall,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Trước: ${change.beforeValue}',
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: colors.borderStrong,
                          ),
                        ),
                        VIcon(
                          icon: VIcons.chevronRight,
                          size: 16,
                          color: colors.textMuted,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceBrand,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: VText(
                            'Sau: ${change.afterValue}',
                            variant: VTextVariant.bodyDefault,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textBrand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
            else ...[
              if (log.beforeRedacted || log.beforeState.isNotEmpty)
                VText(
                  'Trước: ${log.beforeRedacted ? '[Đã che theo chính sách]' : log.beforeState}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              if (log.afterRedacted || log.afterState.isNotEmpty)
                VText(
                  'Sau: ${log.afterRedacted ? '[Đã che theo chính sách]' : log.afterState}',
                  variant: VTextVariant.bodySmall,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textBrand,
                  ),
                ),
            ],
          ],
        ),
      DetailPart(
        title: 'Ngữ cảnh',
        padding: const EdgeInsets.all(20),
        wideHeader: true,
        trailing: log.isActorUnavailable
            ? const VBadge(
                label: 'Không còn dữ liệu',
                tone: VComponentTone.warning,
                variant: VBadgeVariant.soft,
                isSmall: true,
              )
            : isActorLegacy
                ? const VBadge(
                    label: 'Thông tin hiện tại',
                    tone: VComponentTone.neutral,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  )
                : null,
        children: [
          AuditDetailRow(label: 'Người thực hiện', value: log.actorName),
          AuditDetailRow(label: 'Vai trò', value: log.actorRole),
        ],
      ),
      DetailPart(
        title: 'Đối tượng',
        padding: const EdgeInsets.all(20),
        wideHeader: true,
        trailing: log.subjectDisplayOrigin == TenantAuditDisplayOrigin.unavailable
            ? const VBadge(
                label: 'Không còn dữ liệu',
                tone: VComponentTone.warning,
                variant: VBadgeVariant.soft,
                isSmall: true,
              )
            : isSubjectLegacy
                ? const VBadge(
                    label: 'Thông tin hiện tại',
                    tone: VComponentTone.neutral,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  )
                : null,
        children: [
          AuditDetailRow(
            label: subjectLabel,
            value: log.subjectName.isEmpty ? log.targetOrg : log.subjectName,
          ),
          if (detailValue != '—' || log.subjectCode.isNotEmpty)
            AuditDetailRow(
              label: detailLabel,
              value: detailValue != '—' ? detailValue : log.subjectCode,
            ),
        ],
      ),
      DetailPart(
        title: 'Thông tin truy vết',
        padding: const EdgeInsets.all(20),
        wideHeader: true,
        children: [
          AuditDetailRow(
            label: 'Thời điểm',
            value: formatAuditDetailTimestamp(log.timestamp),
          ),
          AuditDetailRow(label: 'Nguồn', value: log.sourceApp),
          if (log.auditDisplayId != null)
            AuditDetailRow(
              label: 'Mã nhật ký',
              value: log.auditDisplayId!,
            ),
          AuditDetailRow(
            label: 'Mã theo dõi',
            value: formatAuditTraceId(log.correlationId),
            copyable: true,
            copyValue: log.correlationId,
            copyTooltip: 'Sao chép mã theo dõi',
          ),
          Text(
            log.actionCode,
            style: VTypography.bodySmall.copyWith(
              fontFamily: 'monospace',
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailHeaderWide(
                leading: AuditIconBox(icon: log.icon, size: 48, iconSize: 22),
                title: log.title,
                subtitle: '${log.actorName} · ${formatAuditTimestamp(log.timestamp)}',
                trailing: auditStatusBadge(log.status),
              ),
              const SizedBox(height: 20),
              if (log.isActorUnavailable) ...[
                VBanner(
                  title: 'Không còn thông tin người thực hiện',
                  description:
                      'Thông tin người thực hiện không còn khả dụng tại thời điểm xem.',
                  tone: VComponentTone.warning,
                ),
                const SizedBox(height: 16),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VRadius.card),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < parts.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.borderDefault),
                      parts[i],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
