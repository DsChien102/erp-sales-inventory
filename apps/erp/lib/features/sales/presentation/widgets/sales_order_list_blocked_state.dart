import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesOrderListBlockedState extends StatelessWidget {
  const SalesOrderListBlockedState({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_e03_u01_scn07_blocked'),
      tone: VComponentTone.warning,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.warning),
              const VEmptyTitle('Không có quyền xem đơn hàng'),
              const VEmptyDescription(
                'Tài khoản của bạn không có quyền truy cập danh sách đơn hàng trong phạm vi này.',
              ),
            ],
          ),
          const VGap(VSpacing.space2),
          VEmptyContent(
            child: VButton(
              label: 'Quay lại',
              variant: VButtonVariant.tertiary,
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
