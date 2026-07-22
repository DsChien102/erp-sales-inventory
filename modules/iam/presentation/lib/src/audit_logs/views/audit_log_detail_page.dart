import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';

/// Trang Chi tiết nhật ký đặc quyền (PA-D-03 — Chi tiết nhật ký đặc quyền).
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
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodyDefault,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
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
      badgeBg = colors.success.withValues(alpha: 0.12);
      badgeFg = colors.success;
    } else if (log.status == AuditLogStatus.blocked) {
      badgeBg = colors.warning.withValues(alpha: 0.12);
      badgeFg = colors.warning;
    } else {
      badgeBg = colors.danger.withValues(alpha: 0.12);
      badgeFg = colors.danger;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Chi tiết hoạt động',
        showBackButton: true,
        leading: IconButton(
          icon: VIcon(
            icon: VIcons.arrowLeft,
            color: colors.textPrimary,
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          children: [
            // Card 1: Top Header Card
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  VIcon(
                    icon: log.icon,
                    size: 24,
                    color: log.icon == VIcons.info ? colors.info : colors.textPrimary,
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          log.title,
                          style: VTypography.bodyDefault.copyWith(
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
                    style: VTypography.bodyDefault.copyWith(
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
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  _buildDetailRow(context, 'Tổ chức', log.targetOrg),
                  const VGap.sm(),
                  _buildDetailRow(context, 'Mã tổ chức', log.targetOrgCode),
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
                    style: VTypography.bodyDefault.copyWith(
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

            // Card 5: Dữ liệu thay đổi
            VCard(
              backgroundColor: colors.surface,
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Dữ liệu thay đổi',
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  _buildDetailRow(context, 'Trước', log.beforeState),
                  const VGap.sm(),
                  _buildDetailRow(context, 'Sau', log.afterState),
                  const VGap.md(),
                  VText(
                    'Dữ liệu nhạy cảm đã được che theo chính sách.',
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
