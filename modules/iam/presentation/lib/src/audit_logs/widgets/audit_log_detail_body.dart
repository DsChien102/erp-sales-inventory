import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/audit_log_ui_model.dart';

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
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  static String _formatStateValue(String? rawState) {
    if (rawState == null || rawState.trim().isEmpty) {
      return '—';
    }
    final trimmed = rawState.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          if (decoded.isEmpty) return '—';
          final parts = <String>[];
          const keyLabels = {
            'given_name': 'Tên',
            'family_middle_name': 'Họ & đệm',
            'phone_number': 'SĐT',
            'display_name': 'Tên hiển thị',
            'status': 'Trạng thái',
            'full_name': 'Họ và tên',
            'email': 'Email',
            'role': 'Vai trò',
          };
          for (final entry in decoded.entries) {
            final label = keyLabels[entry.key] ?? entry.key;
            parts.add('$label: ${entry.value}');
          }
          return parts.join('\n');
        }
      } catch (_) {
        // Fallback to raw string
      }
    }
    return trimmed;
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
    final subjectValue = log.targetSubjectValue ?? '—';
    final detailLabel = log.targetDetailLabel ?? 'Mã';
    final detailValue = log.targetDetailValue ?? '—';

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
                      icon: VIcons.history,
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
                          '${log.actionCode} · ${log.id}',
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
                  VText(
                    'Người thực hiện & ngữ cảnh',
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  _AuditDetailRow(label: 'Người thực hiện', value: log.actorName),
                  const VGap.sm(),
                  _AuditDetailRow(label: 'Loại chủ thể', value: log.actorRole),
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
                    'Đối tượng',
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  _AuditDetailRow(label: subjectLabel, value: subjectValue),
                  const VGap.sm(),
                  _AuditDetailRow(label: detailLabel, value: detailValue),
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
                  _AuditDetailRow(
                    label: 'Thời điểm',
                    value: formatTimestamp(log.timestamp),
                  ),
                  const VGap.sm(),
                  _AuditDetailRow(label: 'Nguồn', value: log.sourceApp),
                  const VGap.sm(),
                  _AuditTrackingIdRow(trackingId: log.correlationId),
                ],
              ),
            ),
            const VGap.md(),
            if (log.isActorUnavailable)
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
              )
            else
              VCard(
                backgroundColor: colors.surface,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VText(
                      log.changeSectionTitle ?? 'Dữ liệu thay đổi',
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const VGap.md(),
                    _AuditDetailRow(
                      label: 'Trước',
                      value: log.beforeRedacted
                          ? '[Đã che]'
                          : _formatStateValue(log.beforeState),
                    ),
                    const VGap.sm(),
                    _AuditDetailRow(
                      label: 'Sau',
                      value: log.afterRedacted
                          ? '[Đã che]'
                          : _formatStateValue(log.afterState),
                    ),
                    if (log.beforeRedacted || log.afterRedacted) ...[
                      const VGap.md(),
                      VText(
                        'Dữ liệu nhạy cảm đã được che theo chính sách.',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            const VGap.xl(),
          ],
        ),
      ),
    );
  }
}

class _AuditDetailRow extends StatelessWidget {
  const _AuditDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: VText(
            value,
            variant: VTextVariant.bodyDefault,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditTrackingIdRow extends StatelessWidget {
  const _AuditTrackingIdRow({required this.trackingId});

  final String trackingId;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          'Mã theo dõi',
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: VText(
                  trackingId,
                  variant: VTextVariant.bodyDefault,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: VIcon(
                  icon: VIcons.clipboard,
                  size: 18,
                  color: colors.textSecondary,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: trackingId));
                  if (!context.mounted) return;
                  VToast.show(
                    context,
                    title: 'Đã sao chép',
                    message: trackingId,
                    type: VToastType.success,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
