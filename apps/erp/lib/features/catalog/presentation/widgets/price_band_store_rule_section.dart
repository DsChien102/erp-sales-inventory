import 'package:flutter/material.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class PriceBandStoreRuleSection extends StatelessWidget {
  const PriceBandStoreRuleSection({super.key, required this.state});

  final EditProductUnitPriceBandLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khung của cửa hàng đang áp dụng',
          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        _ratioRow(
          context,
          'Giá niêm yết',
          state.suggestion.suggestedListBeforeVat,
        ),
        const SizedBox(height: 12),
        _ratioRow(
          context,
          'Giá sàn',
          state.suggestion.suggestedFloorBeforeVat,
        ),
        const SizedBox(height: 16),
        Divider(color: colors.borderDefault),
        const SizedBox(height: 16),
        _priceRow(
          context,
          'Giá niêm yết',
          state.suggestion.suggestedListBeforeVat,
        ),
        const SizedBox(height: 12),
        _priceRow(context, 'Giá sàn', state.suggestion.suggestedFloorBeforeVat),
      ],
    );
  }

  Widget _ratioRow(BuildContext context, String label, int? price) {
    final base = state.suggestion.basePrice;
    final ratio = base == 0 || price == null
        ? '—'
        : '${((price - base) / base * 100).toStringAsFixed(0)}%';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VTypography.bodyDefault),
        Text(ratio, style: VTypography.bodyDefault),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, int? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VTypography.bodyDefault),
        Text(
          price == null ? '—' : formatCatalogCurrency(price),
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
