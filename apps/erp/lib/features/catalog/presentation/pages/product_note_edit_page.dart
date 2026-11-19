import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';

import '../../data/product_repository.dart';
import '../../logic/catalog_error_messages.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductNoteEditRouteArgs {
  final ProductListItemModel product;
  final String? currentNote;

  const ProductNoteEditRouteArgs({
    required this.product,
    this.currentNote,
  });
}

class ProductNoteEditPage extends StatefulWidget {
  const ProductNoteEditPage({
    super.key,
    required this.args,
  });

  final ProductNoteEditRouteArgs args;

  @override
  State<ProductNoteEditPage> createState() => _ProductNoteEditPageState();
}

class _ProductNoteEditPageState extends State<ProductNoteEditPage> {
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.args.currentNote);
    _noteController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onTextChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    final original = widget.args.currentNote ?? '';
    final current = _noteController.text.trim();
    return current != original.trim();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      await GetIt.instance<ProductRepository>().updateProfile(
        productId: widget.args.product.id,
        productName: widget.args.product.name,
        commercialName: widget.args.product.tradeName,
        sku: widget.args.product.sku,
        barcode: widget.args.product.barcode,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        expectedVersion: null,
      );

      if (mounted) {
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Đã lưu ghi chú sản phẩm',
          type: VToastType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: catalogErrorMessage(e, fallback: 'Không lưu được ghi chú'),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        key: const Key('wgt_note_edit_page'),
        backgroundColor: dynamicColors.background,
        appBar: VAppBar(
          showBackButton: true,
          title: 'Ghi chú',
          titleStyle: VTypography.headingH3.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          subtitle: widget.args.product.name,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            VText(
              'Ghi chú riêng cho chính bạn. Không hiển thị cho khách hàng.',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
            const VGap.md(),
            VTextFormField(
              key: const Key('input_product_note'),
              controller: _noteController,
              maxLines: 6,
              maxLength: 500,
              hintText: 'Ví dụ: Hàng nhập từ NCC A, khách hay hỏi tên cũ ABC...',
            ),
          ],
        ),
        bottomNavigationBar: ProductFormBottomBar(
          onCancel: _isSubmitting ? null : () => context.pop(),
          saveKey: const Key('btn_note_save'),
          isLoading: _isSubmitting,
          saveEnabled: _hasChanges,
          onSave: _submit,
        ),
      ),
    );
  }
}
