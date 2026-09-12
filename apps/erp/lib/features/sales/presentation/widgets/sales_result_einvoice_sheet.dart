import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

Future<void> showSalesResultEInvoiceSheet(
  BuildContext context, {
  required IntegrationDeliveryStatus status,
}) {
  return showVBottomSheet<void>(
    context: context,
    title: 'Hóa đơn điện tử',
    semanticLabel: 'Hóa đơn điện tử',
    child: _SalesResultEInvoiceSheetBody(status: status),
  );
}

class _SalesResultEInvoiceSheetBody extends StatelessWidget {
  const _SalesResultEInvoiceSheetBody({required this.status});

  final IntegrationDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final String issueSubtitle = switch (status) {
      IntegrationDeliveryStatus.notRequired => 'Không yêu cầu phát hành cho giao dịch này',
      IntegrationDeliveryStatus.queued => 'Yêu cầu đang xử lý',
      IntegrationDeliveryStatus.delivered => 'Đã phát hành thành công trên hệ thống',
      IntegrationDeliveryStatus.retryScheduled => 'Hệ thống sẽ tự động thử lại',
      IntegrationDeliveryStatus.failed ||
      IntegrationDeliveryStatus.deadLetter => 'Đồng bộ thất bại, cần xử lý thủ công',
      IntegrationDeliveryStatus.unknown => 'Trạng thái chưa xác định',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EInvoiceOptionTile(
            key: const Key('btn_einvoice_status'),
            icon: VIcons.fileCheck,
            title: 'Trạng thái hóa đơn điện tử',
            subtitle: issueSubtitle,
            enabled: false,
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

class _EInvoiceOptionTile extends StatelessWidget {
  const _EInvoiceOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
  }) : onTap = null;

  final VIcons icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final titleColor = enabled ? colors.textPrimary : colors.textMuted;
    final subtitleColor = enabled ? colors.textSecondary : colors.textMuted;

    return VCard(
      onTap: onTap,
      enabled: enabled,
      child: Row(
        children: [
          VIcon(
            icon: icon,
            size: 22,
            color: enabled ? colors.textPrimary : colors.textMuted,
          ),
          const VGap(VSpacing.space3, axis: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  color: titleColor,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  color: subtitleColor,
                  variant: VTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: enabled ? colors.textMuted : colors.borderDefault,
          ),
        ],
      ),
    );
  }
}
