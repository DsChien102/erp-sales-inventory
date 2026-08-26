import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ConfigurationEditorBottomBar extends StatelessWidget {
  const ConfigurationEditorBottomBar({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.cancelLabel = 'Hủy',
    this.submitLabel = 'Lưu',
    this.isLoading = false,
    this.submitEnabled = true,
    this.submitKey,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final bool isLoading;
  final bool submitEnabled;
  final Key? submitKey;

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
                variant: VButtonVariant.secondary,
                onPressed: isLoading ? null : onCancel,
              ),
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: VButton(
                key: submitKey,
                label: submitLabel,
                variant: VButtonVariant.primary,
                isLoading: isLoading,
                onPressed: submitEnabled && !isLoading ? onSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
