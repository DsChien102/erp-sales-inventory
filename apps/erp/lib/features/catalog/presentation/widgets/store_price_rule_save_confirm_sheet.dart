import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Hiển thị bottom sheet cảnh báo khi cập nhật quy tắc giá cửa hàng.
Future<bool?> showStorePriceRuleSaveConfirmSheet(BuildContext context) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: const StorePriceRuleSaveConfirmSheet(),
  );
}

class StorePriceRuleSaveConfirmSheet extends StatelessWidget {
  const StorePriceRuleSaveConfirmSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space5,
          VSpacing.space4,
          VSpacing.space5,
          VSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: VIconBox(
                icon: VIcons.warning,
                size: 64,
                iconSize: 32,
                isCircular: true,
                backgroundColor: dynamicColors.warning.withValues(alpha: 0.15),
                iconColor: dynamicColors.warning,
              ),
            ),
            const SizedBox(height: VSpacing.space4),
            VText(
              'Áp dụng quy tắc lên sản phẩm đã có giá?',
              textAlign: TextAlign.center,
              variant: VTextVariant.headingH3,
              color: dynamicColors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Thay đổi tỷ lệ lãi/sàn sẽ tự động áp dụng và cập nhật lại giá bán cho toàn bộ sản phẩm đang sử dụng "Khung giá cửa hàng".',
              textAlign: TextAlign.center,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_store_price_rule_confirm_cancel'),
                    label: 'Hủy',
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: VButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_store_price_rule_confirm_save'),
                    label: 'Áp dụng',
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: VButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
