import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import '../models/sales_order_cancellation/sales_order_cancellation_vm.dart';

/// S27 cancellation result card. Shows authoritative reason and cancellation
/// metadata; no refund status/action (EP-05).
class SalesOrderDetailCancelReasonCard extends StatelessWidget {
  const SalesOrderDetailCancelReasonCard({
    super.key,
    required this.cancellation,
    required this.status,
    this.errorMessage,
    this.onRetry,
  });

  final SalesOrderCancellationVm? cancellation;
  final SalesOrderDetailSectionStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == SalesOrderDetailSectionStatus.loaded &&
        (cancellation?.reason.trim().isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return VCard(
      key: const Key('card_sg08_cancellation'),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VText(
            'Lý do hủy',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.sm(),
          _content(context),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final colors = context.vColors;
    switch (status) {
      case SalesOrderDetailSectionStatus.loading:
      case SalesOrderDetailSectionStatus.idle:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: VSpacing.space2),
          child: Center(child: CircularProgressIndicator()),
        );
      case SalesOrderDetailSectionStatus.projectionPending:
        return VText(
          'Đang cập nhật kết quả hủy đơn...',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        );
      case SalesOrderDetailSectionStatus.blocked:
        return VText(
          errorMessage ?? 'Bạn không có quyền xem kết quả hủy đơn.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        );
      case SalesOrderDetailSectionStatus.error:
        return Row(
          children: [
            Expanded(
              child: VText(
                errorMessage ?? 'Không tải được kết quả hủy đơn.',
                variant: VTextVariant.bodySmall,
                color: colors.danger,
              ),
            ),
            if (onRetry != null)
              VButton(
                key: const Key('btn_sg08_cancellation_retry'),
                label: 'Thử lại',
                variant: VButtonVariant.secondary,
                size: VButtonSize.small,
                onPressed: onRetry,
              ),
          ],
        );
      case SalesOrderDetailSectionStatus.loaded:
        final vm = cancellation;
        if (vm == null) return const SizedBox.shrink();
        return _loaded(context, vm);
    }
  }

  Widget _loaded(BuildContext context, SalesOrderCancellationVm vm) {
    final colors = context.vColors;
    final subtitle = [
      vm.cancelledByActorName.trim(),
      vm.cancelledAtFormatted,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          vm.reason,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (subtitle.isNotEmpty) ...[
          const VGap.xs(),
          VText(
            subtitle,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ],
    );
  }
}
