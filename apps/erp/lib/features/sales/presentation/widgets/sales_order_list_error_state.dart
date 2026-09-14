import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesOrderListErrorState extends StatelessWidget {
  const SalesOrderListErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_e03_u01_error'),
      tone: VComponentTone.danger,
      bordered: true,
      backgroundColor: context.vColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.error),
              const VEmptyTitle('Không thể tải danh sách'),
              VEmptyDescription(message),
            ],
          ),
          const VGap(VSpacing.space2),
          VEmptyContent(
            child: VButton(
              label: 'Thử lại',
              onPressed: onRetry,
              variant: VButtonVariant.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
