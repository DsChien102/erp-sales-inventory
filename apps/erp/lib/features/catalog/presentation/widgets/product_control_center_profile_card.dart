import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:erp/features/catalog/presentation.dart' hide formatCatalogCurrency;
import 'package:c45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';

class ProductControlCenterProfileCard extends StatelessWidget {
  const ProductControlCenterProfileCard({
    super.key,
    required this.profile,
    required this.priceBand,
    required this.stock,
  });

  final ProductProfileSummaryDto profile;
  final ProductPriceBandCardDto priceBand;
  final ProductStockCardDto stock;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final imageReference = profile.primaryImageUrl;

    final listPriceText = priceBand.isMissing || priceBand.listAfterVat == null
        ? 'Giá niêm yết: --'
        : 'Giá niêm yết: ${formatCatalogCurrency(priceBand.listAfterVat)}';

    final stockUnit = stock.unitName ?? 'cơ sở';
    final stockText = stock.isMissing
        ? 'Tồn ($stockUnit): Chưa thiết lập'
        : 'Tồn ($stockUnit): ${stock.quantity ?? 0}${stock.isOutOfStock ? ' (Hết hàng)' : ''}';

    return VCard(
      child: Row(
        children: [
          if (imageReference != null && imageReference.isNotEmpty)
            CatalogStorageImage(
              storageReference: imageReference,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(VRadius.r8),
              placeholder: VIconBox(
                size: 64,
                iconSize: 32,
                icon: VIcons.image,
                backgroundColor: dynamicColors.surfaceAlt,
                iconColor: dynamicColors.textMuted,
              ),
            )
          else
            VIconBox(
              size: 64,
              iconSize: 32,
              icon: VIcons.image,
              backgroundColor: dynamicColors.surfaceAlt,
              iconColor: dynamicColors.textMuted,
            ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  profile.name,
                  variant: VTextVariant.bodyDefault,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.xs(),
                VText(
                  listPriceText,
                  variant: VTextVariant.bodyDefault,
                ),
                const VGap.xs(),
                VText(
                  stockText,
                  variant: VTextVariant.bodySmall,
                  color: dynamicColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
