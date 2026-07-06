import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

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
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final quantity = double.tryParse(_quantityController.text) ?? 0;

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
          SetInitialStockCommand(
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
            expectedQuantity: widget.args.currentQuantity?.toDouble(),
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

    return Scaffold(
      key: const Key('wgt_e05_u01_fr01_01'),
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        showBackButton: true,
        title: 'Tồn kho',
        titleStyle: VTypography.headingH3.copyWith(
          color: dynamicColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        subtitle: unitName.isNotEmpty ? unitName : widget.args.product.name,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
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
                  Text(
                    'Tồn hiện tại',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isInitial ? 'Chưa thiết lập' : '${widget.args.currentQuantity}',
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tồn mới
            Text(
              'Tồn mới ($unitName)',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('input_stock_quantity'),
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập số tồn thực tế',
                hintStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: dynamicColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: dynamicColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  borderSide: BorderSide(color: dynamicColors.primary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tồn thực tế';
                }
                final qty = double.tryParse(value);
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
              const SizedBox(height: 24),
              // Lý do
              Text(
                'Lý do',
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedReasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(
                      reason,
                      style: VTypography.bodyDefault.copyWith(
                        color: isSelected ? dynamicColors.surface : dynamicColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedReason = selected ? reason : null;
                      });
                    },
                    showCheckmark: false,
                    selectedColor: dynamicColors.success,
                    backgroundColor: dynamicColors.background,
                    side: BorderSide(
                      color: isSelected ? dynamicColors.success : dynamicColors.borderDefault,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Ghi chú
              Text(
                'Ghi chú (không bắt buộc)',
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                    borderSide: BorderSide(color: dynamicColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                    borderSide: BorderSide(color: dynamicColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                    borderSide: BorderSide(color: dynamicColors.primary),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'Thay đổi sẽ ghi vào Lịch sử. Ở Growth, tồn được đọc từ module Kho (read-only).',
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dynamicColors.background,
            border: Border(
              top: BorderSide(color: dynamicColors.borderDefault),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: BorderSide(color: dynamicColors.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                  ),
                ),
                child: Text(
                  'Huỷ',
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                key: const Key('btn_stock_save'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: dynamicColors.success,
                  foregroundColor: dynamicColors.surface,
                  disabledBackgroundColor: dynamicColors.success.withValues(alpha: 0.4),
                  disabledForegroundColor: dynamicColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.input),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Lưu thay đổi',
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
