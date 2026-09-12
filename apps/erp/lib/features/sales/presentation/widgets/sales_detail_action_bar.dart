import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';

class SalesDetailActionBar extends StatelessWidget {
  const SalesDetailActionBar({
    super.key,
    required this.vm,
    required this.onOpenActions,
    this.actionsReady = true,
  });

  final SalesOrderDetailVm vm;
  final VoidCallback onOpenActions;
  final bool actionsReady;

  @override
  Widget build(BuildContext context) {
    if (vm.isCancelled) {
      return const SizedBox.shrink();
    }

    return VPagePadding(
      vertical: VSpacing.space3,
      child: VButton(
        key: const Key('btn_sg08_actions'),
        label: 'Thao tác',
        variant: VButtonVariant.primary,
        tone: VComponentTone.success,
        size: VButtonSize.large,
        fullWidth: true,
        trailingIcon: const VIcon(
          icon: VIcons.expandLess,
          iconColor: VIconColor.white,
          iconSize: VIconSize.sm,
        ),
        onPressed: actionsReady ? onOpenActions : null,
      ),
    );
  }
}
