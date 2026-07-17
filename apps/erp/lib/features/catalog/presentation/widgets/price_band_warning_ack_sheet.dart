import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

Future<bool?> showPriceBandWarningAckSheet(BuildContext context) {
  return showVBottomSheet<bool>(
    context: context,
    child: const PriceBandWarningAckSheet(),
  );
}

class PriceBandWarningAckSheet extends StatelessWidget {
  const PriceBandWarningAckSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xác nhận cảnh báo giá',
              style: VTypography.headingH3.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Khung giá có thể thấp hơn giá vốn hoặc biên lợi nhuận mong muốn. Bạn vẫn muốn lưu?',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_price_band_warning_confirm'),
                    label: 'Tiếp tục lưu',
                    onPressed: () => Navigator.of(context).pop(true),
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
