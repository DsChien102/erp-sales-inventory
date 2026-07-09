import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

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
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  double _overlayWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.baseUnit);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ProductGuidedStepBaseUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.baseUnit != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.state.baseUnit;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
        LayoutBuilder(
          builder: (context, constraints) {
            _overlayWidth = constraints.maxWidth;
            return CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                key: const Key('input_guided_base_unit'),
                controller: _controller,
                focusNode: _focusNode,
                decoration: ProductGuidedFields.buildInputDecoration(
                  context,
                  'Ví dụ: Hộp, Chai, Bao...',
                ),
                style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                onChanged: (val) {
                  cubit.updateBaseUnit(val);
                  setState(() {});
                },
              ),
            );
          },
        ),
        OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) {
            return Positioned(
              width: _overlayWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: Material(
                  elevation: 8,
                  color: dynamicColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                    side: BorderSide(color: dynamicColors.borderDefault),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildAutocompleteList(context, widget.state, cubit),
                ),
              ),
            );
          },
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

  Widget _buildAutocompleteList(BuildContext context, ProductGuidedCreateState state, ProductGuidedCreateCubit cubit) {
    final dynamicColors = context.vColors;
    final query = _controller.text.trim().toLowerCase();
    final availableUnits = state.tenantUnits;

    List<TenantMeasurementUnitDto> filteredUnits = availableUnits;
    if (query.isNotEmpty) {
      filteredUnits = availableUnits
          .where((u) => u.name.toLowerCase().contains(query))
          .toList();
    }

    if (query.isEmpty) {
      if (availableUnits.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxHeight: 250),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Đơn vị đã có trong cửa hàng', style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary)),
              const SizedBox(height: 8),
              ...availableUnits.map((u) => _buildAutocompleteItem(context, u, cubit)),
            ],
          ),
        ),
      );
    } else {
      if (filteredUnits.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 250),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Không tìm thấy đơn vị phù hợp', style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary)),
                const SizedBox(height: 8),
                Listener(
                  onPointerDown: (_) {
                    _focusNode.unfocus();
                  },
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: VColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Tạo đơn vị mới: "$query"', style: VTypography.bodyDefault.copyWith(color: VColors.success)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 250),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...filteredUnits.map((u) => _buildAutocompleteItem(context, u, cubit)),
              ],
            ),
          ),
        );
      }
    }
  }

  Widget _buildAutocompleteItem(BuildContext context, TenantMeasurementUnitDto u, ProductGuidedCreateCubit cubit) {
    final dynamicColors = context.vColors;
    return Listener(
      onPointerDown: (_) {
        _controller.text = u.name;
        cubit.updateBaseUnit(u.name);
        _focusNode.unfocus();
        setState(() {});
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.sell_outlined, size: 18, color: dynamicColors.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(u.name, style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
