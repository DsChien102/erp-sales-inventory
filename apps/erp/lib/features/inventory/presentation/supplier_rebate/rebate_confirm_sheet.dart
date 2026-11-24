import 'package:erp/core/formatting/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Sheet xác nhận trước khi ghi nhận chiết khấu nhà cung cấp (P4).
Future<bool> showRebateConfirmSheet(
  BuildContext context, {
  required int amountVnd,
  required int affectedProductCount,
}) async {
  final formattedAmount = '${MoneyFormatter.formatMinorPlain(amountVnd)} đ';
  final confirmed = await showVAdaptiveSheet<bool>(
    context: context,
    title: 'Ghi nhận chiết khấu $formattedAmount?',
    child: Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Giá trị tồn và bình quân của $affectedProductCount sản phẩm sẽ giảm. Không hoàn tác được.',
            variant: VTextVariant.bodyDefault,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space4),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Huỷ',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Expanded(
                child: VButton(
                  label: 'Ghi nhận',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

