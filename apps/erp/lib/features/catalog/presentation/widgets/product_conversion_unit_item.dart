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
        borderRadius: BorderRadius.circular(VRadius.r8),
        child: InkWell(
          key: Key('btn_expand_conversion_unit_${unit.id}'),
          onLongPress: _expand,
          borderRadius: BorderRadius.circular(VRadius.r8),
          child: Container(
            padding: const EdgeInsets.all(VSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(color: dynamicColors.borderDefault),
              borderRadius: BorderRadius.circular(VRadius.r8),
              color: cardColor,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(VSpacing.space2),
                      decoration: BoxDecoration(
                        color: isInactive ? dynamicColors.borderDefault : dynamicColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(VRadius.r8),
                      ),
                      child: VIcon(
                        icon: VIcons.inventory,
                        color: dynamicColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: VText(
                                  unit.name,
                                  variant: VTextVariant.bodyDefault,
                                  color: isInactive
                                      ? dynamicColors.textSecondary
                                      : dynamicColors.textPrimary,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  child: VText(
                                    'Đã tắt',
                                    variant: VTextVariant.caption,
                                    color: dynamicColors.textSecondary,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: VSpacing.space1),
                          VText(
                            unit.name,
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    VText(
                      '${_formatRate(unit.conversionRateToBase)} x ${widget.baseUnitName}',
                      variant: VTextVariant.bodyDefault,
                      color: isInactive ? dynamicColors.textSecondary : dynamicColors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: VSpacing.space3),
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
                                context.read<ProductMeasurementUnitsCubit>().deleteConversionUnit(
                                  unit.id,
                                );
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
                  const SizedBox(height: VSpacing.space1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: VText(
                      'giữ để mở',
                      variant: VTextVariant.caption,
                      color: dynamicColors.textMuted,
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
