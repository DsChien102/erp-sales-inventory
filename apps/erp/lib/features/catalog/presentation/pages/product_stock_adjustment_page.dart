import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_stock_adjustment_cubit.dart';
import 'package:erp/features/catalog/logic/product_stock_adjustment_state.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../widgets/dashed_border_container.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductStockAdjustmentRouteArgs {
  final ProductListItemModel product;
  final int? currentQuantity;
  final String? unitName;
  final int? stockVersion;

  const ProductStockAdjustmentRouteArgs({
    required this.product,
    this.currentQuantity,
    this.unitName,
    this.stockVersion,
  });
}

class ProductStockAdjustmentPage extends StatelessWidget {
  const ProductStockAdjustmentPage({
    super.key,
    required this.args,
  });

  final ProductStockAdjustmentRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductStockAdjustmentCubit(
        productRepository: GetIt.instance<ProductRepository>(),
      ),
      child: _ProductStockAdjustmentView(args: args),
    );
  }
}

class _ProductStockAdjustmentView extends StatefulWidget {
  const _ProductStockAdjustmentView({required this.args});

  final ProductStockAdjustmentRouteArgs args;

  @override
  State<_ProductStockAdjustmentView> createState() => _ProductStockAdjustmentViewState();
}

class _ProductStockAdjustmentViewState extends State<_ProductStockAdjustmentView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;

  final List<String> _predefinedReasons = ['Kiểm kê', 'Nhập tay', 'Hao hụt', 'Khác'];
  String? _selectedReason;

  bool get _isInitial => widget.args.currentQuantity == null;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
    _quantityController.addListener(() => setState(() {}));
    _noteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (_quantityController.text.trim().isNotEmpty) return true;
    if (_selectedReason != null) return true;
    if (!_isInitial && _noteController.text.trim().isNotEmpty) return true;
    return false;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    context.read<ProductStockAdjustmentCubit>().submit(
      productId: widget.args.product.id,
      quantity: quantity,
      currentQuantity: widget.args.currentQuantity,
      chip: _selectedReason,
      note: _noteController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final unitName = widget.args.unitName ?? widget.args.product.baseUnit ?? '';
    final bool hasBaseUnit = unitName.trim().isNotEmpty;

    return BlocConsumer<ProductStockAdjustmentCubit, ProductStockAdjustmentState>(
      listener: (context, state) {
        if (state.status == ProductStockAdjustmentStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: _isInitial ? 'Đã nhập tồn kho ban đầu' : 'Đã điều chỉnh tồn kho',
            type: VToastType.success,
          );
          Navigator.of(context).pop(true);
        } else if (state.status == ProductStockAdjustmentStatus.failure) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage ?? 'Đã xảy ra lỗi. Vui lòng thử lại.',
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == ProductStockAdjustmentStatus.loading;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: VPageScaffold(
            key: const Key('wgt_e05_u01_fr01_01'),
            title: 'Tồn kho',
            showBackButton: true,
            subtitle: widget.args.product.name,
            body: hasBaseUnit
                ? Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      children: [
                        // Tồn hiện tại (Read-only view)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: dynamicColors.borderDefault),
                            borderRadius: BorderRadius.circular(VRadius.input),
                            color: dynamicColors.background,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              VText(
                                'Tồn hiện tại',
                                variant: VTextVariant.bodyDefault,
                                color: dynamicColors.textPrimary,
                              ),
                              VText(
                                _isInitial ? 'Chưa thiết lập' : '${widget.args.currentQuantity}',
                                variant: VTextVariant.bodyDefault,
                                color: dynamicColors.textPrimary,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VSpacing.space6),

                        // Tồn mới
                        VText(
                          'Tồn mới ($unitName)',
                          variant: VTextVariant.bodyDefault,
                          color: dynamicColors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: VSpacing.space2),
                        VTextFormField(
                          key: const Key('input_stock_quantity'),
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          hintText: 'Nhập số tồn thực tế',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số tồn thực tế';
                            }
                            if (value.contains('.') || value.contains(',')) {
                              return 'Tồn kho phải là số nguyên';
                            }
                            final val = int.tryParse(value);
                            if (val == null) {
                              return 'Số lượng không hợp lệ';
                            }
                            if (val < 0) {
                              return 'Tồn kho không được âm';
                            }
                            return null;
                          },
                        ),

                        if (!_isInitial) ...[
                          const SizedBox(height: VSpacing.space6),
                          // Lý do
                          VText(
                            'Lý do',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                          const SizedBox(height: VSpacing.space2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _predefinedReasons.map((reason) {
                              final isSelected = _selectedReason == reason;
                              return ChoiceChip(
                                label: VText(
                                  reason,
                                  variant: VTextVariant.bodyDefault,
                                  color: isSelected ? dynamicColors.surface : dynamicColors.textPrimary,
                                ),
                                selected: isSelected,
                                onSelected: isSubmitting
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          _selectedReason = selected ? reason : null;
                                        });
                                      },
                                showCheckmark: false,
                                selectedColor: dynamicColors.success,
                                side: BorderSide(
                                  color: isSelected
                                      ? dynamicColors.success
                                      : dynamicColors.borderDefault,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(VRadius.r20),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: VSpacing.space6),

                          // Ghi chú
                          VText(
                            'Ghi chú (không bắt buộc)',
                            variant: VTextVariant.bodySmall,
                            color: dynamicColors.textSecondary,
                          ),
                          const SizedBox(height: VSpacing.space2),
                          VTextFormField(
                            controller: _noteController,
                            maxLines: 4,
                            maxLength: 500,
                            enabled: !isSubmitting,
                          ),
                        ],

                        const SizedBox(height: VSpacing.space6),
                        VText(
                          'Thay đổi sẽ ghi vào Lịch sử thay đổi.',
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.textSecondary,
                        ),
                      ],
                    ),
                  )
                : _buildMissingBaseUnit(context),
            bottomBar: hasBaseUnit
                ? ProductFormBottomBar(
                    onCancel: isSubmitting ? null : () => context.pop(),
                    saveKey: const Key('btn_stock_save'),
                    isLoading: isSubmitting,
                    saveEnabled: _hasChanges && !isSubmitting,
                    onSave: _hasChanges && !isSubmitting ? () => _submit(context) : null,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMissingBaseUnit(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: DashedBorderContainer(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.textPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Cần thiết lập '),
                          TextSpan(
                            text: 'đơn vị cơ sở',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' cho sản phẩm trước khi thiết lập tồn kho.'),
                        ],
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      'Tồn kho được tính theo đơn vị cơ sở của sản phẩm.',
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ProductFormBottomBar(
          onCancel: () => context.pop(),
          saveEnabled: false,
          onSave: null,
        ),
      ],
    );
  }
}
