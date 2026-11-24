import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SalesTransactionResultActionBar extends StatelessWidget {
  const SalesTransactionResultActionBar({
    super.key,
    required this.onGoHome,
    required this.onCreateNewOrder,
    this.isErrorState = false,
    this.onRetryLoad,
  });

  final VoidCallback onGoHome;
  final VoidCallback onCreateNewOrder;
  final bool isErrorState;
  final VoidCallback? onRetryLoad;

  @override
  Widget build(BuildContext context) {
    return VPagePadding(
      vertical: VSpacing.space3,
      child: Row(
        children: [
          Expanded(
            child: VButton(
              key: const Key('btn_sg06_home'),
              label: 'Về trang chủ',
              variant: VButtonVariant.secondary,
              tone: VComponentTone.success,
              fullWidth: true,
              onPressed: onGoHome,
            ),
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: VButton(
              key: const Key('btn_sg06_new_order'),
              label: isErrorState ? 'Thử tải lại' : 'Tạo đơn mới',
              tone: isErrorState ? VComponentTone.danger : VComponentTone.success,
              fullWidth: true,
              onPressed: isErrorState ? onRetryLoad : onCreateNewOrder,
            ),
          ),
        ],
      ),
    );
  }
}
