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
    this.onEditUnits,
    this.onEditStock,
    this.onEditBasePrice,
    this.onEditPriceBand,
  });

  final ProductUnitsCardDto units;
  final ProductStockCardDto stock;
  final ProductBasePriceCardDto basePrice;
  final ProductPriceBandCardDto priceBand;
  final VoidCallback? onEditUnits;
  final VoidCallback? onEditStock;
  final VoidCallback? onEditBasePrice;
  final VoidCallback? onEditPriceBand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductControlCenterSectionCard(
          icon: Icons.straighten,
          title: 'Đơn vị đo lường',
          subtitle: units.isMissing
              ? (units.missingMessage ?? 'Chưa thiết lập')
              : units.baseUnitName ?? 'Chưa thiết lập',
          onEdit: onEditUnits,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Tồn kho',
          subtitle: stock.isMissing
              ? (stock.missingMessage ?? 'Chưa thiết lập')
              : '${stock.quantity ?? 0}${stock.unitName != null ? ' ${stock.unitName}' : ''}',
          onEdit: onEditStock,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.monetization_on_outlined,
          title: 'Giá cơ sở',
          subtitle: basePrice.isMissing
              ? (basePrice.missingMessage ?? 'Chưa thiết lập')
              : formatCatalogCurrency(basePrice.amount),
          onEdit: onEditBasePrice,
        ),
        ProductControlCenterSectionCard(
          icon: Icons.local_offer_outlined,
          title: 'Khung giá',
          subtitle: _priceBandSubtitle(),
          onEdit: onEditPriceBand,
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
    final unitSuffix = unit != null && unit.isNotEmpty ? ' · Đơn vị: $unit' : '';

    final metadataSuffix = () {
      if (priceBand.isCustomOverride) {
        return ' · Giá riêng';
      }
      if (priceBand.sourceType == PriceBandSourceType.ruleBased &&
          priceBand.storePriceRuleName != null &&
          priceBand.storePriceRuleName!.trim().isNotEmpty) {
        return ' · ${priceBand.storePriceRuleName}';
      }
      return '';
    }();

    return '$listPart · $floorPart$unitSuffix$metadataSuffix';
  }
}

class ProductControlCenterSectionCard extends StatelessWidget {
  const ProductControlCenterSectionCard({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.actionText = 'Sửa',
    this.hasError = false,
  });

  final IconData? icon;
  final String? emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final String actionText;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onEdit,
        child: VCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (emoji != null && emoji!.isNotEmpty)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasError ? dynamicColors.dangerBg : dynamicColors.surfaceBrand,
                    borderRadius: BorderRadius.circular(VRadius.iconBox),
                  ),
                  child: Text(
                    emoji!,
                    style: const TextStyle(fontSize: 20),
                  ),
                )
              else
                VIconBox(
                  iconData: icon ?? Icons.assignment_outlined,
                  size: 40,
                  iconSize: 20,
                  backgroundColor: hasError ? dynamicColors.dangerBg : dynamicColors.surfaceBrand,
                  iconColor: hasError ? dynamicColors.danger : dynamicColors.primary,
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
                    if (hasError) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            'Thiếu thông tin bắt buộc',
                            style: VTypography.caption.copyWith(
                              color: dynamicColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  actionText,
                  style: VTypography.bodyDefault.copyWith(
                    color: hasError ? dynamicColors.primary : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
