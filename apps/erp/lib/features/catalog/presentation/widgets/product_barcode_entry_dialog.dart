import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductBarcodeEntryDialog extends StatefulWidget {
  const ProductBarcodeEntryDialog({super.key});

  @override
  State<ProductBarcodeEntryDialog> createState() => _ProductBarcodeEntryDialogState();
}

class _ProductBarcodeEntryDialogState extends State<ProductBarcodeEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Giả lập quét Barcode',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            VText(
              'Nhập mã Barcode để giả lập hành động quét qua Camera.',
              variant: VTextVariant.bodySmall,
              color: dynamicColors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space3),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mã Barcode / Mã vạch',
                hintText: 'Ví dụ: 893000001',
              ),
              autofocus: true,
            ),
            const SizedBox(height: VSpacing.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: VText(
                    'Hủy',
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VButton(
                  label: 'Xác nhận',
                  onPressed: () {
                    final code = _controller.text.trim();
                    if (code.isNotEmpty) {
                      Navigator.pop(context, code);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
