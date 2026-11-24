import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Dialog VBottomSheet cảnh báo khi người dùng nhấn Back nhưng chưa lưu thay đổi phiếu đổi/trả (Image 4).
Future<bool?> showSalesReturnDiscardDialog(BuildContext context) {
  return showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Bỏ thay đổi?',
    child: const _SalesReturnDiscardDialogBody(),
  );
}

class _SalesReturnDiscardDialogBody extends StatelessWidget {
  const _SalesReturnDiscardDialogBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPagePadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Bỏ thay đổi?',
            variant: VTextVariant.headingH3,
            color: colors.danger,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          VText(
            'Hàng trả và hàng đổi vừa chọn chưa được lưu.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          VButton(
            key: const Key('btn_return_discard_continue_edit'),
            label: 'Tiếp tục đổi/trả',
            variant: VButtonVariant.secondary,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('btn_return_discard_confirm'),
            label: 'Bỏ thay đổi',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
