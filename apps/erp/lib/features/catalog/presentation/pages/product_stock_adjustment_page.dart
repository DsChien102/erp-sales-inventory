import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

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

class ProductStockAdjustmentPage extends StatefulWidget {
  const ProductStockAdjustmentPage({
    super.key,
    required this.args,
  });

  final ProductStockAdjustmentRouteArgs args;

  @override
  State<ProductStockAdjustmentPage> createState() => _ProductStockAdjustmentPageState();
}

class _ProductStockAdjustmentPageState extends State<ProductStockAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    // Combine reason and note if both exist, or just use the one that exists
    String? finalReason;
    final note = _noteController.text.trim();
    if (_selectedReason != null && note.isNotEmpty) {
      finalReason = '$_selectedReason - $note';
    } else if (_selectedReason != null) {
      finalReason = _selectedReason;
    } else if (note.isNotEmpty) {
      finalReason = note;
    }

    try {
      final catalogModule = GetIt.instance<ICatalogModule>();
      final executionContext = GetIt.instance<IExecutionContext>();
      final tenantId = await executionContext.requireTenantId();

      if (_isInitial) {
        await catalogModule.executeCommandAsync(
          SetBasicStockQuantityBaseCommand(
            tenantId: tenantId,
            productId: widget.args.product.id,
            quantity: quantity,
          ),
        );
      } else {
        await catalogModule.executeCommandAsync(
          AdjustBasicStockCommand(
            tenantId: tenantId,
            productId: widget.args.product.id,
            newQuantity: quantity,
            reason: finalReason,
            expectedQuantity: widget.args.currentQuantity,
          ),
        );
      }

      if (mounted) {
        VToast.show(
          context,
          title: 'Thành công',
          message: _isInitial ? 'Đã nhập tồn kho ban đầu' : 'Đã điều chỉnh tồn kho',
          type: VToastType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: e.toString(),
          type: VToastType.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final unitName = widget.args.unitName ?? widget.args.product.baseUnit ?? '';

    final bool hasBaseUnit = widget.args.unitName != null && widget.args.unitName!.isNotEmpty;

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
                        final raw = value.trim().replaceAll(',', '');
                        if (raw.contains('.') || raw.contains(',')) {
                          return 'Tồn kho phải là số nguyên';
                        }
                        final qty = int.tryParse(raw);
                        if (qty == null) {
                          return 'Số lượng không hợp lệ';
                        }
                        if (qty < 0) {
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
                            onSelected: (selected) {
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
                      ),
                    ],

                    const SizedBox(height: VSpacing.space6),
                    VText(
                      'Thay đổi sẽ ghi vào Lịch sử. Ở Growth, tồn được đọc từ module Kho (read-only).',
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.textSecondary,
                    ),
                  ],
                ),
              )
            : _buildMissingBaseUnit(context),
        bottomBar: hasBaseUnit
            ? ProductFormBottomBar(
                onCancel: _isSubmitting ? null : () => context.pop(),
                saveKey: const Key('btn_stock_save'),
                isLoading: _isSubmitting,
                saveEnabled: _hasChanges,
                onSave: _submit,
              )
            : null,
      ),
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
