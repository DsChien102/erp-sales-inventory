import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

class ProductLifecycleActionSheet extends StatelessWidget {
  const ProductLifecycleActionSheet({
    super.key,
    required this.productId,
    required this.productName,
    required this.onDeleteRequested,
  });

  final String productId;
  final String productName;
  final VoidCallback onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VBottomSheet(
      title: 'Nâng cao',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: VIcon(
              icon: VIcons.delete,
              color: dynamicColors.danger,
            ),
            title: VText(
              'Xóa sản phẩm',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.danger,
            ),
            onTap: () {
              context.pop();
              onDeleteRequested();
            },
          ),
          const SizedBox(height: VSpacing.space4),
        ],
      ),
    );
  }
}
