import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../data/models/tenant_audit_log.dart';
import '../../shared/detail_layout.dart';
import '../models/audit_log_ui_model.dart';
import 'audit_detail_row.dart';
import 'detail_part.dart';

/// Thân trang chi tiết hoạt động trên màn hình hẹp.
class AuditDetailNarrow extends StatelessWidget {
  const AuditDetailNarrow({super.key, required this.log});

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
          children: [
            if (log.changes.isNotEmpty)
              for (final change in log.changes)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      change.fieldLabel,
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      'Trước: ${change.beforeValue}',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      'Sau: ${change.afterValue}',
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textBrand,
                      ),
                    ),
                  ],
                )
            else ...[
              if (log.beforeRedacted || log.beforeState.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Trước',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      log.beforeRedacted
                          ? '[Đã che theo chính sách]'
                          : log.beforeState,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              if (log.afterRedacted || log.afterState.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Sau',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    VText(
                      log.afterRedacted
                          ? '[Đã che theo chính sách]'
                          : log.afterState,
                      variant: VTextVariant.bodySmall,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textBrand,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      DetailPart(
        title: 'Ngữ cảnh',
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
          _TraceRow(
            display: formatAuditTraceId(log.correlationId),
            value: log.correlationId,
          ),
          Text(
            log.actionCode,
            style: VTypography.caption.copyWith(
              fontFamily: 'monospace',
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
      children: [
        DetailHeaderNarrow(
          leading: DetailIconTile(log.icon),
          title: log.title,
          subtitle: '${log.actorName} · ${formatAuditTimestamp(log.timestamp)}',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: auditStatusBadge(log.status),
        ),
        const SizedBox(height: 16),
        if (log.isActorUnavailable) ...[
          VBanner(
            title: 'Không còn thông tin người thực hiện',
            description:
                'Thông tin người thực hiện không còn khả dụng tại thời điểm xem.',
            tone: VComponentTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        VCard(
          padding: EdgeInsets.zero,
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
    );
  }
}

/// Proto `traceRow()` (`.t1-adm__trace`): nhãn trên, mã monospace dưới, nút sao chép 44 bên phải (lề phải −10).
class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.display, required this.value});

  final String display;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Mã theo dõi',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              Text(
                display,
                style: VTypography.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Transform.translate(
          offset: const Offset(10, 0),
          child: AuditCopyButton(
            value: value,
            tooltip: 'Sao chép mã theo dõi',
          ),
        ),
      ],
    );
  }
}
