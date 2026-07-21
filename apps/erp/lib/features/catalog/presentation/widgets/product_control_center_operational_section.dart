import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_control_center_formatters.dart';
import 'product_control_center_section_card.dart';

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
      spacing: VSpacing.space2,
      children: [
        ProductControlCenterSectionCard(
          icon: VIcons.straighten,
          title: 'Đơn vị đo lường',
          subtitle: units.isMissing
              ? (units.missingMessage ?? 'Chưa thiết lập')
              : units.baseUnitName ?? 'Chưa thiết lập',
          onEdit: onEditUnits,
        ),
        ProductControlCenterSectionCard(
          icon: VIcons.inventory,
          title: 'Tồn kho',
          subtitle: stock.isMissing
              ? (stock.missingMessage ?? 'Chưa thiết lập')
              : '${stock.quantity ?? 0}${stock.unitName != null ? ' ${stock.unitName}' : ''}${stock.isOutOfStock ? ' (Hết hàng)' : ''}',
          onEdit: onEditStock,
        ),
        ProductControlCenterSectionCard(
          icon: VIcons.coins,
          title: 'Giá cơ sở',
          subtitle: basePrice.isMissing
              ? (basePrice.missingMessage ?? 'Chưa thiết lập')
              : formatCatalogCurrency(basePrice.amount),
          onEdit: onEditBasePrice,
        ),
        ProductControlCenterSectionCard(
          icon: VIcons.tag,
          title: 'Khung giá',
          subtitle: _priceBandSubtitle(),
          onEdit: onEditPriceBand,
        ),
      ],
    );
  }

  String _priceBandSubtitle() {
    if (priceBand.isPendingCalculation) {
      return 'Đã cấu hình – chờ Giá cơ sở';
    }
    if (priceBand.isMissing) {
      return priceBand.missingMessage ?? 'Chưa thiết lập khung giá bán';
    }

    final listPart = priceBand.listBeforeVat != null
        ? 'Niêm yết: ${formatCatalogCurrency(priceBand.listBeforeVat)}'
        : 'Niêm yết: --';
    final floorPart = priceBand.floorBeforeVat != null
        ? 'Sàn: ${formatCatalogCurrency(priceBand.floorBeforeVat)}'
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
