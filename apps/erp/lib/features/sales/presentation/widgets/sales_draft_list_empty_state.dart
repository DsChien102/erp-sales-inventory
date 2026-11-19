import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// D-03 — Chưa có đơn nháp.
class SalesDraftListEmptyState extends StatelessWidget {
  final void Function()? onRetry;

  const SalesDraftListEmptyState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      filled: true,
      border: VBorders.all(context.vColors.borderDefault),
      backgroundColor: context.vColors.surface,
      key: Key('wgt_e01_u01_empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.info),
              VEmptyTitle('Chưa có đơn nháp'),
              VEmptyDescription('Các đơn được lưu nháp sẽ xuất hiện tại đây.'),
            ],
          ),
          const VGap.xs(),
          VEmptyContent(
            child: VButton(
              label: 'Tải lại',
              variant: VButtonVariant.tertiary,
              tone: VComponentTone.success,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
