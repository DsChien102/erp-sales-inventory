import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class CustomFieldDeactivateConfirmSheet extends StatelessWidget {
  const CustomFieldDeactivateConfirmSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showVAdaptiveSheet<bool>(
      context: context,
      child: const CustomFieldDeactivateConfirmSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space5,
          VSpacing.space4,
          VSpacing.space5,
          VSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Tạm tắt trường này?',
              variant: VTextVariant.headingH3,
              color: dynamicColors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Dữ liệu đã nhập trên sản phẩm sẽ được giữ lại. '
              'Trường sẽ không hiển thị khi tạo/sửa sản phẩm mới.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_deactivate_field_cancel'),
                    label: 'Huỷ',
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: VButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_deactivate_field_confirm'),
                    label: 'Tạm tắt',
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
