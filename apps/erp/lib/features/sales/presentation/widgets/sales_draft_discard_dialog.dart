import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/sales_order_draft/sales_draft_list_item_vm.dart';

/// O-01 — Xác nhận xóa đơn nháp (VBottomSheet).
Future<bool> showSalesDraftDiscardDialog(
  BuildContext context, {
  required SalesDraftListItemVm item,
}) async {
  final buttonSize = context.vDensity.mode == VDensityMode.compact
      ? VButtonSize.medium
      : VButtonSize.large;
  final result = await showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Xóa đơn nháp',
    child: VPagePadding(
      child: Column(
        key: const Key('wgt_sg01_delete_draft_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Xóa đơn nháp?',
            variant: VTextVariant.headingH3,
            color: context.vColors.danger,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          VText(
            'Đơn nháp của ${item.customerLabel} sẽ bị xóa và không thể khôi phục.',
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textSecondary,
          ),
          const VGap.lg(),
          VButton(
            key: const Key('btn_delete_draft_confirm'),
            label: 'Xóa',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            size: buttonSize,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('btn_delete_draft_cancel'),
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            size: buttonSize,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
