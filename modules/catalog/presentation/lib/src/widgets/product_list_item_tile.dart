import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductListItemTile extends StatelessWidget {
  const ProductListItemTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ProductListItemDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(dynamicColors),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  item.name,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  color: dynamicColors.textPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.isSoftDeleted) ...[
                  const VGap.xs(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: VBadge(
                      label: 'Đã xóa',
                      status: VBadgeStatus.locked,
                      isSmall: true,
                    ),
                  ),
                ],
                if (item.tradeName != null && item.tradeName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  VText(
                    item.tradeName!,
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ],
                if (item.customFieldValues.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.customFieldValues.map((cf) {
                      String displayVal = cf.displayValue;
                      if (cf.fieldType == CustomFieldType.number.name) {
                        final parsed = double.tryParse(cf.displayValue);
                        if (parsed != null) {
                          if (parsed == parsed.roundToDouble()) {
                            displayVal = VNumberValidator.format(
                              parsed.round(),
                              allowDecimal: false,
                            );
                          } else {
                            displayVal = VNumberValidator.format(parsed, allowDecimal: true);
                          }
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: dynamicColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: VText(
                          '${cf.fieldName}: $displayVal',
                          variant: VTextVariant.bodySmall,
                          style: const TextStyle(fontSize: 11),
                          color: dynamicColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const VGap.sm(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildPriceInfo(dynamicColors),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildUnitInfo(dynamicColors),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildStockInfo(dynamicColors),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic colors) {
    final reference = item.primaryImageUrl;
    if (reference != null && reference.isNotEmpty) {
      return CatalogStorageImage(
        storageReference: reference,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        placeholder: _buildPlaceholder(colors),
      );
    }
    return _buildPlaceholder(colors);
  }

  Widget _buildPlaceholder(dynamic colors) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: VIcon(
        icon: VIcons.image,
        color: colors.textSecondary,
        size: 24,
      ),
    );
  }

  Widget _buildPriceInfo(dynamic colors) {
    if (item.listBeforeVat != null) {
      return VText(
        formatCatalogCurrency(item.listBeforeVat),
        variant: VTextVariant.bodyDefault,
        style: const TextStyle(fontWeight: FontWeight.w700),
        color: colors.textPrimary,
      );
    }
    return VText(
      '_',
      variant: VTextVariant.bodyDefault,
      color: colors.textMuted,
    );
  }

  Widget _buildUnitInfo(dynamic colors) {
    if (item.baseUnit != null && item.baseUnit!.isNotEmpty) {
      return VText(
        item.baseUnit!.toLowerCase(),
        variant: VTextVariant.bodySmall,
        color: colors.textSecondary,
      );
    }
    return VText(
      '–',
      variant: VTextVariant.bodySmall,
      color: colors.textMuted,
    );
  }

  Widget _buildStockInfo(dynamic colors) {
    if (item.stockQuantity == null) {
      return VText(
        'Chưa TL tồn',
        maxLines: 1,
        variant: VTextVariant.bodySmall,
        color: colors.textSecondary,
      );
    }
    if (item.stockLabel != null && item.stockLabel!.isNotEmpty) {
      final isOutOfStock = item.stockQuantity == 0;
      return VText(
        isOutOfStock ? 'Hết' : item.stockLabel!,
        variant: VTextVariant.bodyDefault,
        color: isOutOfStock ? colors.warning : colors.textPrimary,
        style: TextStyle(
          fontWeight: isOutOfStock ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
