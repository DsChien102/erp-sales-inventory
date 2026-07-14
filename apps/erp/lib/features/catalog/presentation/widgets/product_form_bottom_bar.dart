import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Standard cancel/save footer for Theme-2 product form pages.
/// Matches Product Images maintenance: white bar, top border, equal-width buttons.
class ProductFormBottomBar extends StatelessWidget {
  const ProductFormBottomBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.cancelLabel = 'Huỷ',
    this.saveLabel = 'Lưu thay đổi',
    this.isLoading = false,
    this.saveEnabled = true,
    this.saveKey,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String cancelLabel;
  final String saveLabel;
  final bool isLoading;
  final bool saveEnabled;
  final Key? saveKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.borderDefault),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: cancelLabel,
                variant: VButtonVariant.outline,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: VSpacing.space4),
            Expanded(
              child: VButton(
                key: saveKey,
                label: saveLabel,
                variant: VButtonVariant.primary,
                isLoading: isLoading,
                onPressed: saveEnabled && !isLoading ? onSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
