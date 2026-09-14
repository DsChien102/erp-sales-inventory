import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-05 — Không thể tải đơn nháp.
class SalesDraftListErrorState extends StatelessWidget {
  const SalesDraftListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VEmptyState(
      key: const Key('wgt_e01_u01_error'),
      filled: true,
      backgroundColor: colors.surface,
      border: VBorders.all(colors.borderDefault),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(
                icon: VIcons.close,
                tone: VComponentTone.danger,
              ),
              VText(
                'Không thể tải đơn nháp',
                variant: VTextVariant.headingH3,
                textAlign: TextAlign.center,
                color: colors.danger,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              VEmptyDescription(
                message.isEmpty ? 'Kiểm tra kết nối và thử lại danh sách.' : message,
              ),
            ],
          ),
          const VGap.xs(),
          VEmptyContent(
            child: VButton(
              key: const Key('btn_draft_list_retry'),
              label: 'Thử lại',
              variant: VButtonVariant.tertiary,
              tone: VComponentTone.danger,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
