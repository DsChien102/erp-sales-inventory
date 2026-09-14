import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesResultFailureView extends StatelessWidget {
  const SalesResultFailureView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      tone: VComponentTone.danger,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.close, size: 56),
              const VEmptyTitle('Không tải được chi tiết kết quả'),
              VEmptyDescription(message),
            ],
          ),
          const VGap.sm(),
          VEmptyContent(
            child: VButton(
              key: const Key('btn_sales_result_retry_load'),
              label: 'Thử tải lại',
              variant: VButtonVariant.tertiary,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
