import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

String _formatCurrency(double? amount) {
  if (amount == null) return '—';
  final str = amount.toStringAsFixed(0);
  final formatted = str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$formatted đ';
}

class EditProductUnitPriceBandRouteArgs {
  final ProductListItemModel product;
  final String? unitName;

  const EditProductUnitPriceBandRouteArgs({
    required this.product,
    this.unitName,
  });
}

class ProductPriceBandsRouteArgs {
  final ProductListItemModel product;
  final ProductBasePriceCardDto basePriceCard;
  final ProductPriceBandCardDto priceBandCard;
  final String? unitName;

  const ProductPriceBandsRouteArgs({
    required this.product,
    required this.basePriceCard,
    required this.priceBandCard,
    this.unitName,
  });
}

class ProductPriceBandsPage extends StatelessWidget {
  const ProductPriceBandsPage({
    super.key,
    required this.product,
    required this.basePriceCard,
    required this.priceBandCard,
    this.unitName,
  });

  final ProductListItemModel product;
  final ProductBasePriceCardDto basePriceCard;
  final ProductPriceBandCardDto priceBandCard;
  final String? unitName;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        title: 'Khung giá bán',
        titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
        subtitle: product.name,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
          onPressed: () => context.pop(true),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ĐƠN VỊ & KHUNG GIÁ BÁN',
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: dynamicColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        unitName ?? 'Đơn vị cơ sở',
                        style: VTypography.headingH3,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await context.push<bool>(
                            '/products/items/pcc/edit-price-band',
                            extra: EditProductUnitPriceBandRouteArgs(
                              product: product,
                              unitName: unitName,
                            ),
                          );
                          if (result == true && context.mounted) {
                            context.pop(true); // Return to PCC to refresh
                          }
                        },
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
                  const SizedBox(height: 8),
                  Text(
                    'Đơn vị cơ sở',
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    'Giá cơ sở',
                    _formatCurrency(basePriceCard.amount),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Giá niêm yết',
                    _formatCurrency(priceBandCard.listPrice),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Giá sàn',
                    _formatCurrency(priceBandCard.floorPrice),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Thay đổi có áp dụng cho cửa hàng và kênh phân phối.',
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: context.vColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: VTypography.bodyDefault.copyWith(
            color: context.vColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
