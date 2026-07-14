import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';

/// Hiển thị bottom sheet cảnh báo ghi đè khi áp dụng quy tắc lên sản phẩm đã có giá.
Future<bool?> showPriceBandOverwriteDialog(
  BuildContext context, {
  int? existingListBeforeVat,
  int? existingFloorBeforeVat,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: PriceBandOverwriteBottomSheet(
      key: const Key('dlg_price_band_overwrite'),
      existingListBeforeVat: existingListBeforeVat,
      existingFloorBeforeVat: existingFloorBeforeVat,
    ),
  );
}

class PriceBandOverwriteBottomSheet extends StatelessWidget {
  const PriceBandOverwriteBottomSheet({
    super.key,
    this.existingListBeforeVat,
    this.existingFloorBeforeVat,
  });

  final int? existingListBeforeVat;
  final int? existingFloorBeforeVat;

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
            Text(
              'Ghi đè khung giá hiện tại?',
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Sản phẩm đã có khung giá bán. Áp dụng quy tắc cửa hàng sẽ thay thế giá hiện tại.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (existingListBeforeVat != null || existingFloorBeforeVat != null) ...[
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
                    if (existingListBeforeVat != null)
                      Text(
                        'Niêm yết hiện tại: ${formatCatalogCurrency(existingListBeforeVat!)}',
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.textPrimary,
                        ),
                      ),
                    if (existingListBeforeVat != null && existingFloorBeforeVat != null)
                      const SizedBox(height: VSpacing.space1),
                    if (existingFloorBeforeVat != null)
                      Text(
                        'Sàn hiện tại: ${formatCatalogCurrency(existingFloorBeforeVat!)}',
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.textPrimary,
                        ),
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
                    variant: VButtonVariant.outline,
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
