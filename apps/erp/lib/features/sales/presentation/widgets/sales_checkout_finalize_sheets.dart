import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

enum SalesCheckoutFinalizeAction { back, confirm }

Future<SalesCheckoutFinalizeAction?> showSalesCheckoutFinalizeSheet(
  BuildContext context,
) {
  return showVBottomSheet<SalesCheckoutFinalizeAction>(
    context: context,
    semanticLabel: 'Xác nhận hoàn tất đơn',
    child: VPagePadding(
      child: const _SalesCheckoutFinalizeSheetBody(),
    ),
  );
}

class _SalesCheckoutFinalizeSheetBody extends StatelessWidget {
  const _SalesCheckoutFinalizeSheetBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VText(
          'Hoàn tất đơn?',
          variant: VTextVariant.headingH4,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        VText(
          'Hệ thống sẽ ghi nhận các khoản đã thu, công nợ phát sinh nếu có và hoàn tất đơn. Vui lòng kiểm tra lại trước khi xác nhận.',
          variant: VTextVariant.bodySmall,
          color: context.vColors.textSecondary,
        ),
        const VGap.md(),
        VButton(
          key: const Key('btn_sg05_finalize_confirm'),
          label: 'Hoàn tất đơn',
          tone: VComponentTone.success,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(SalesCheckoutFinalizeAction.confirm),
        ),
        const VGap.sm(),
        VButton(
          key: const Key('btn_sg05_finalize_back'),
          label: 'Quay lại',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(SalesCheckoutFinalizeAction.back),
        ),
        const VGap.sm(),
      ],
    );
  }
}
