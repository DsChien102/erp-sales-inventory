import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: dynamicColors.borderDefault),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(dynamicColors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: VTypography.bodyDefault.copyWith(
                            color: dynamicColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.sku != null && item.sku!.isNotEmpty)
                        Text(
                          ' - ${item.sku}',
                          style: VTypography.bodyDefault.copyWith(
                            color: dynamicColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                    ],
                  ),
                  if (item.isSoftDeleted) ...[
                    const SizedBox(height: 4),
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
                    Text(
                      item.tradeName!,
                      style: VTypography.bodySmall.copyWith(
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                  ],
                  if (item.customFieldValues.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.customFieldValues.map((cf) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: dynamicColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${cf.fieldName}: ${cf.displayValue}',
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildPriceInfo(dynamicColors),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(child: _buildUnitInfo(dynamicColors)),
                      ),
                      Expanded(
                        flex: 1,
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
      child: Icon(
        Icons.image_outlined,
        color: colors.textSecondary,
        size: 24,
      ),
    );
  }

  Widget _buildPriceInfo(dynamic colors) {
    if (item.listPrice != null) {
      return Text(
        '${item.listPrice}đ',
        style: VTypography.bodyDefault.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Text(
      '—',
      style: VTypography.bodyDefault.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildUnitInfo(dynamic colors) {
    if (item.baseUnit != null && item.baseUnit!.isNotEmpty) {
      return Text(
        item.baseUnit!.toLowerCase(),
        style: VTypography.bodySmall.copyWith(
          color: colors.textSecondary,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStockInfo(dynamic colors) {
    if (item.stockLabel != null && item.stockLabel!.isNotEmpty) {
      final isOutOfStock = item.stockLabel!.toLowerCase() == 'hết';
      return Text(
        isOutOfStock ? 'Hết' : item.stockLabel!,
        style: VTypography.bodyDefault.copyWith(
          color: isOutOfStock ? colors.warning : colors.textPrimary,
          fontWeight: isOutOfStock ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
