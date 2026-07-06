import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';

class ProductControlCenterOperationalSection extends StatelessWidget {
  const ProductControlCenterOperationalSection({
    super.key,
    required this.units,
    required this.stock,
    required this.basePrice,
    required this.priceBand,
    this.onEdit,
  });

  final ProductUnitsCardDto units;
  final ProductStockCardDto stock;
  final ProductBasePriceCardDto basePrice;
  final ProductPriceBandCardDto priceBand;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductControlCenterSectionCard(
          icon: Icons.straighten,
          title: 'Đơn vị',
          subtitle: units.isMissing
              ? (units.missingMessage ?? 'Chưa thiết lập')
              : units.baseUnitName ?? 'Chưa thiết lập',
          onEdit: onEdit,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Tồn kho',
          subtitle: stock.isMissing
              ? (stock.missingMessage ?? 'Chưa thiết lập')
              : '${stock.quantity ?? 0}${stock.unitName != null ? ' ${stock.unitName}' : ''}',
          onEdit: onEdit,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.monetization_on_outlined,
          title: 'Giá cơ sở',
          subtitle: basePrice.isMissing
              ? (basePrice.missingMessage ?? 'Chưa thiết lập')
              : formatCatalogCurrency(basePrice.amount),
          onEdit: onEdit,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.local_offer_outlined,
          title: 'Khung giá',
          subtitle: _priceBandSubtitle(),
          onEdit: onEdit,
        ),
      ],
    );
  }

  String _priceBandSubtitle() {
    if (priceBand.isMissing) {
      return priceBand.missingMessage ?? 'Chưa thiết lập khung giá bán';
    }

    final listPart = priceBand.listPrice != null
        ? 'Niêm yết: ${formatCatalogCurrency(priceBand.listPrice)}'
        : 'Niêm yết: --';
    final floorPart = priceBand.floorPrice != null
        ? 'Sàn: ${formatCatalogCurrency(priceBand.floorPrice)}'
        : 'Sàn: --';
    final unit = priceBand.unitName?.trim();
    final unitSuffix =
        unit != null && unit.isNotEmpty ? ' · Đơn vị: $unit' : '';

    return '$listPart · $floorPart$unitSuffix';
  }
}

class ProductControlCenterSectionCard extends StatelessWidget {
  const ProductControlCenterSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: VCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            VIconBox(
              iconData: icon,
              size: 40,
              iconSize: 20,
              backgroundColor: dynamicColors.surfaceBrand,
              iconColor: dynamicColors.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Text(
                'Sửa',
                style: VTypography.bodyDefault.copyWith(
                  color: dynamicColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
