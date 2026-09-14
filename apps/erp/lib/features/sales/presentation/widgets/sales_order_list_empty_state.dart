import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class SalesOrderListEmptyState extends StatelessWidget {
  const SalesOrderListEmptyState({
    super.key,
    this.onCreateSale,
  });

  final VoidCallback? onCreateSale;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_e03_u01_scn05_empty'),
      bordered: true,
      backgroundColor: context.vColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.info),
              VEmptyTitle('Chưa có đơn hàng'),
              VEmptyDescription('Đơn hàng hoàn tất sẽ xuất hiện tại đây.'),
            ],
          ),
          const VGap(VSpacing.space2),
          VEmptyContent(
            child: VButton(
              label: 'Tạo đơn bán hàng',
              variant: VButtonVariant.tertiary,
              onPressed: onCreateSale,
            ),
          ),
        ],
      ),
    );
  }
}
