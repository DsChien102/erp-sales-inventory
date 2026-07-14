import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';
import 'tenant_measurement_unit_search_field.dart';

class ProductGuidedStepBaseUnit extends StatefulWidget {
  const ProductGuidedStepBaseUnit({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  State<ProductGuidedStepBaseUnit> createState() => _ProductGuidedStepBaseUnitState();
}

class _ProductGuidedStepBaseUnitState extends State<ProductGuidedStepBaseUnit> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.baseUnit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ProductGuidedCreateCubit>().loadTenantMeasurementUnits();
    });
  }

  @override
  void didUpdateWidget(ProductGuidedStepBaseUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.baseUnit != _controller.text) {
      _controller.text = widget.state.baseUnit;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Đơn vị gốc để tính tồn/giá. Có thể bổ sung sau.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(context, 'Đơn vị cơ sở'),
        TenantMeasurementUnitSearchField(
          controller: _controller,
          units: widget.state.tenantUnits,
          isUnitsLoading: widget.state.isTenantUnitsLoading,
          onChanged: cubit.updateBaseUnit,
          hintText: 'Ví dụ: hộp, thùng...',
          inputDecoration: ProductGuidedFields.buildInputDecoration(
            context,
            'Ví dụ: hộp, thùng...',
          ),
          textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
        ),
        const SizedBox(height: VSpacing.space2),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(
          context,
          showSkip: true,
          showNext: true,
        ),
      ],
    );
  }
}
