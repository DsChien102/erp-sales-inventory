import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_conversion_unit_delete_confirm_dialog.dart';

class ProductConversionUnitItem extends StatelessWidget {
  const ProductConversionUnitItem({
    super.key,
    required this.unit,
    required this.baseUnitName,
  });

  final ProductUnitDto unit;
  final String baseUnitName;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: dynamicColors.borderDefault),
          borderRadius: BorderRadius.circular(8),
          color: dynamicColors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dynamicColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2_outlined, color: dynamicColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.bold,
                      color: unit.isActive
                          ? dynamicColors.textPrimary
                          : dynamicColors.textSecondary,
                      decoration: unit.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Muted text below unit name as in design
                  Text(
                    unit.name,
                    style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${unit.conversionRateToBase} x $baseUnitName',
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        VToast.show(
                          context, 
                          title: 'Thông báo', 
                          message: 'Tính năng sửa đơn vị đang phát triển', 
                          type: VToastType.info,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 32),
                        side: BorderSide(color: dynamicColors.borderDefault),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Sửa', style: VTypography.bodySmall.copyWith(color: dynamicColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        key: Key('btn_more_conversion_unit_${unit.id}'),
                        icon: Icon(Icons.more_horiz, color: dynamicColors.textSecondary),
                        padding: EdgeInsets.zero,
                        position: PopupMenuPosition.under,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: dynamicColors.borderDefault),
                        ),
                        onSelected: (val) {
                          if (val == 'toggle') {
                            if (unit.isActive) {
                              context.read<ProductMeasurementUnitsCubit>().deactivateConversionUnit(unit.id);
                            } else {
                              context.read<ProductMeasurementUnitsCubit>().reactivateConversionUnit(unit.id);
                            }
                          } else if (val == 'delete') {
                            ProductConversionUnitDeleteConfirmDialog.show(
                              context,
                              unitName: unit.name,
                              onConfirm: () {
                                context.read<ProductMeasurementUnitsCubit>().deleteConversionUnit(unit.id);
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            key: Key('btn_toggle_conversion_unit_${unit.id}'),
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(unit.isActive ? Icons.visibility_off : Icons.visibility, size: 20),
                                const SizedBox(width: 12),
                                Text(unit.isActive ? 'Tắt đơn vị' : 'Bật đơn vị'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            key: Key('btn_delete_conversion_unit_${unit.id}'),
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 20, color: VColors.danger),
                                const SizedBox(width: 12),
                                Text('Xoá', style: VTypography.bodyDefault.copyWith(color: VColors.danger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
