import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';

Future<bool?> showPriceBandOverwriteDialog(
  BuildContext context, {
  double? existingListPrice,
  double? existingFloorPrice,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('dlg_price_band_overwrite'),
        title: const Text('Ghi đè khung giá hiện tại?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm đã có khung giá bán. Áp dụng quy tắc cửa hàng sẽ thay thế giá hiện tại.',
            ),
            if (existingListPrice != null || existingFloorPrice != null) ...[
              const SizedBox(height: 12),
              if (existingListPrice != null)
                Text('Niêm yết hiện tại: ${formatCatalogCurrency(existingListPrice)}'),
              if (existingFloorPrice != null)
                Text('Sàn hiện tại: ${formatCatalogCurrency(existingFloorPrice)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('btn_price_band_overwrite_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            key: const Key('btn_price_band_overwrite_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ghi đè'),
          ),
        ],
      );
    },
  );
}
