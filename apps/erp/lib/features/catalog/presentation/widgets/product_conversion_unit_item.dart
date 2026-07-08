import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _isExpanded = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: dynamicColors.borderDefault),
            borderRadius: BorderRadius.circular(8),
            color: dynamicColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unit.name,
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.unit.isActive
                              ? dynamicColors.textPrimary
                              : dynamicColors.textSecondary,
                          decoration: widget.unit.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 ${widget.unit.name} = ${widget.unit.conversionRateToBase} ${widget.baseUnitName}',
                        style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
                      ),
                    ],
                  ),
                  InkWell(
                    key: Key('btn_expand_conversion_unit_${widget.unit.id}'),
                    onTap: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    child: Text(
                      'Giữ để mở',
                      style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Divider(color: dynamicColors.borderDefault, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        OutlinedButton(
                          key: Key('btn_toggle_conversion_unit_${widget.unit.id}'),
                          onPressed: () {
                            if (widget.unit.isActive) {
                              context.read<ProductMeasurementUnitsCubit>().deactivateConversionUnit(
                                widget.unit.id,
                              );
                            } else {
                              context.read<ProductMeasurementUnitsCubit>().reactivateConversionUnit(
                                widget.unit.id,
                              );
                            }
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: dynamicColors.borderDefault),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            widget.unit.isActive ? 'Tắt đơn vị' : 'Bật đơn vị',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            VToast.show(
                              context,
                              title: 'Thông báo',
                              message: 'Tính năng xoá đơn vị đang phát triển',
                              type: VToastType.info,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dynamicColors.danger,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Xoá',
                            style: VTypography.bodyDefault.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      child: Text(
                        'Đóng',
                        style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
