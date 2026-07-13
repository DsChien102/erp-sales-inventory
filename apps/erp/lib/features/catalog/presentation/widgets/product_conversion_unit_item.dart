import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_conversion_unit_deactivate_confirm_dialog.dart';
import 'product_conversion_unit_delete_confirm_dialog.dart';
import 'product_conversion_unit_reactivate_confirm_dialog.dart';

class ProductConversionUnitItem extends StatefulWidget {
  const ProductConversionUnitItem({
    super.key,
    required this.unit,
    required this.baseUnitName,
  });

  final ProductUnitDto unit;
  final String baseUnitName;

  @override
  State<ProductConversionUnitItem> createState() => _ProductConversionUnitItemState();
}

class _ProductConversionUnitItemState extends State<ProductConversionUnitItem> {
  bool _isExpanded = false;

  void _expand() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  /// Hiển thị 100 thay vì 100.0 khi phần thập phân bằng 0.
  static String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) {
      return rate.toInt().toString();
    }
    return rate.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final unit = widget.unit;
    final isInactive = !unit.isActive;
    final cardColor = isInactive ? dynamicColors.surfaceAlt : dynamicColors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('btn_expand_conversion_unit_${unit.id}'),
          onLongPress: _expand,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: dynamicColors.borderDefault),
              borderRadius: BorderRadius.circular(8),
              color: cardColor,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isInactive
                            ? dynamicColors.borderDefault
                            : dynamicColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: dynamicColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  unit.name,
                                  style: VTypography.bodyDefault.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isInactive
                                        ? dynamicColors.textSecondary
                                        : dynamicColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isInactive) ...[
                                const SizedBox(width: VSpacing.space2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VSpacing.space2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: dynamicColors.surface,
                                    borderRadius: BorderRadius.circular(VRadius.r4),
                                    border: Border.all(
                                      color: dynamicColors.borderDefault,
                                    ),
                                  ),
                                  child: Text(
                                    'Đã tắt',
                                    style: VTypography.caption.copyWith(
                                      color: dynamicColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.name,
                            style: VTypography.bodySmall.copyWith(
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatRate(unit.conversionRateToBase)} x ${widget.baseUnitName}',
                      style: VTypography.bodyDefault.copyWith(
                        color: isInactive
                            ? dynamicColors.textSecondary
                            : dynamicColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: VButton(
                          key: Key('btn_toggle_conversion_unit_${unit.id}'),
                          label: unit.isActive ? 'Tắt đơn vị' : 'Bật đơn vị',
                          variant: VButtonVariant.outline,
                          size: VButtonSize.small,
                          fullWidth: true,
                          onPressed: () {
                            if (unit.isActive) {
                              ProductConversionUnitDeactivateConfirmDialog.show(
                                context,
                                unitName: unit.name,
                                onConfirm: () {
                                  context
                                      .read<ProductMeasurementUnitsCubit>()
                                      .deactivateConversionUnit(unit.id);
                                },
                              );
                            } else {
                              ProductConversionUnitReactivateConfirmDialog.show(
                                context,
                                unitName: unit.name,
                                onConfirm: () {
                                  context
                                      .read<ProductMeasurementUnitsCubit>()
                                      .reactivateConversionUnit(unit.id);
                                },
                              );
                            }
                            _collapse();
                          },
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      Expanded(
                        child: VButton(
                          key: Key('btn_delete_conversion_unit_${unit.id}'),
                          label: 'Xoá',
                          variant: VButtonVariant.danger,
                          size: VButtonSize.small,
                          fullWidth: true,
                          onPressed: () {
                            ProductConversionUnitDeleteConfirmDialog.show(
                              context,
                              unitName: unit.name,
                              onConfirm: () {
                                context
                                    .read<ProductMeasurementUnitsCubit>()
                                    .deleteConversionUnit(unit.id);
                              },
                            );
                            _collapse();
                          },
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      VButton(
                        label: 'Đóng',
                        variant: VButtonVariant.ghost,
                        size: VButtonSize.small,
                        foregroundColor: dynamicColors.textSecondary,
                        onPressed: _collapse,
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'giữ để mở',
                      style: VTypography.caption.copyWith(
                        color: dynamicColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
