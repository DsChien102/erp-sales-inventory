import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';

/// Hiển thị bottom sheet cảnh báo ghi đè khi áp dụng quy tắc lên sản phẩm đã có giá.
/// Amounts are after-VAT (catalog display default).
Future<bool?> showPriceBandOverwriteDialog(
  BuildContext context, {
  int? existingListAfterVat,
  int? existingFloorAfterVat,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: PriceBandOverwriteBottomSheet(
      key: const Key('dlg_price_band_overwrite'),
      existingListAfterVat: existingListAfterVat,
      existingFloorAfterVat: existingFloorAfterVat,
    ),
  );
}

class PriceBandOverwriteBottomSheet extends StatelessWidget {
  const PriceBandOverwriteBottomSheet({
    super.key,
    this.existingListAfterVat,
    this.existingFloorAfterVat,
  });

  final int? existingListAfterVat;
  final int? existingFloorAfterVat;

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
            VText(
              'Ghi đè khung giá hiện tại?',
              variant: VTextVariant.headingH3,
              color: dynamicColors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Sản phẩm đã có khung giá bán. Áp dụng quy tắc cửa hàng sẽ thay thế giá hiện tại.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (existingListAfterVat != null || existingFloorAfterVat != null) ...[
              const SizedBox(height: VSpacing.space4),
              Container(
                padding: const EdgeInsets.all(VSpacing.space3),
                decoration: BoxDecoration(
                  color: dynamicColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r8),
                  border: Border.all(color: dynamicColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (existingListAfterVat != null)
                      VText(
                        'Niêm yết hiện tại: ${formatCatalogCurrency(existingListAfterVat!)}',
                        variant: VTextVariant.bodyDefault,
                        color: dynamicColors.textPrimary,
                      ),
                    if (existingListAfterVat != null && existingFloorAfterVat != null)
                      const SizedBox(height: VSpacing.space1),
                    if (existingFloorAfterVat != null)
                      VText(
                        'Sàn hiện tại: ${formatCatalogCurrency(existingFloorAfterVat!)}',
                        variant: VTextVariant.bodyDefault,
                        color: dynamicColors.textPrimary,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_price_band_overwrite_cancel'),
                    label: 'Hủy',
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: VButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_price_band_overwrite_confirm'),
                    label: 'Ghi đè',
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
