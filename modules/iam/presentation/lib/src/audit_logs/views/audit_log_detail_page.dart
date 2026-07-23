import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';

/// Trang Chi tiết nhật ký đặc quyền (TA-D-02, TA-D-03, TA-D-04).
class AuditLogDetailPage extends StatelessWidget {
  final AuditLogItemUiModel log;
  final VoidCallback? onBackPressed;

  const AuditLogDetailPage({
    super.key,
    required this.log,
    this.onBackPressed,
  });

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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

    final subjectLabel = log.targetSubjectLabel ?? 'Tổ chức';
    final subjectValue = log.targetSubjectValue ?? log.targetOrg;
    final detailLabel = log.targetDetailLabel ?? 'Mã tổ chức';
    final detailValue = log.targetDetailValue ?? log.targetOrgCode;

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
        title: VText(
          'Chi tiết hoạt động',
          variant: VTextVariant.headingH4,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
            // Card 1: Top Header Card
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

            // Card 2: Người thực hiện & ngữ cảnh
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
                  _buildDetailRow(context, 'Người thực hiện', log.actorName),
                  const VGap.sm(),
                  _buildDetailRow(context, 'Loại chủ thể', log.actorRole),
                ],
              ),
            ),
            const VGap.md(),

            // Card 3: Đối tượng
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
                  _buildDetailRow(context, subjectLabel, subjectValue),
                  const VGap.sm(),
                  _buildDetailRow(context, detailLabel, detailValue),
                ],
              ),
            ),
            const VGap.md(),

            // Card 4: Thông tin truy vết
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
                  _buildDetailRow(context, 'Thời điểm', _formatTimestamp(log.timestamp)),
                  const VGap.sm(),
                  _buildDetailRow(context, 'Nguồn', log.sourceApp),
                  const VGap.sm(),
                  _buildDetailRow(context, 'Mã theo dõi', log.correlationId),
                ],
              ),
            ),
            const VGap.md(),

            // Card 5: Bottom Section (Warning Banner OR Change Data Card)
            if (log.isActorUnavailable)
              VCard(
                backgroundColor: colors.warningBg,
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VText(
                      'Người thực hiện không còn khả dụng',
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.warning,
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      'Tên hiển thị và mã người dùng tại thời điểm phát sinh vẫn được giữ để phục vụ truy vết.',
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
                    const VGap.sm(),
                    VText(
                      'Trước: ${log.beforeState}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.xs(),
                    VText(
                      'Sau: ${log.afterState}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
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
