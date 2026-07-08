import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

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

    final listPriceText = priceBand.isMissing
        ? 'Giá niêm yết: --'
        : 'Giá niêm yết: ${formatCatalogCurrency(priceBand.listPrice)}';

    final stockUnit = stock.unitName ?? 'cơ sở';
    final stockText = stock.isMissing
        ? 'Tồn ($stockUnit): Chưa thiết lập'
        : 'Tồn ($stockUnit): ${stock.quantity ?? 0}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: VCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (imageReference != null && imageReference.isNotEmpty)
              CatalogStorageImage(
                storageReference: imageReference,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                placeholder: VIconBox(
                  size: 64,
                  iconSize: 32,
                  iconData: Icons.image_outlined,
                  backgroundColor: dynamicColors.surfaceAlt,
                  iconColor: dynamicColors.textMuted,
                ),
              )
            else
              VIconBox(
                size: 64,
                iconSize: 32,
                iconData: Icons.image_outlined,
                backgroundColor: dynamicColors.surfaceAlt,
                iconColor: dynamicColors.textMuted,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listPriceText,
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stockText,
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
