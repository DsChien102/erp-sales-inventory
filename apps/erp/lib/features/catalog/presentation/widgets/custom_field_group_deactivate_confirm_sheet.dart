import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class CustomFieldGroupDeactivateConfirmSheet extends StatelessWidget {
  const CustomFieldGroupDeactivateConfirmSheet({
    super.key,
    required this.fieldCount,
    required this.requiredFieldCount,
  });

  final int fieldCount;
  final int requiredFieldCount;

  static Future<bool?> show(
    BuildContext context, {
    required int fieldCount,
    required int requiredFieldCount,
  }) {
    return showVBottomSheet<bool>(
      context: context,
      child: CustomFieldGroupDeactivateConfirmSheet(
        fieldCount: fieldCount,
        requiredFieldCount: requiredFieldCount,
      ),
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
            Text(
              'Tạm tắt nhóm này?',
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Nhóm đang có $fieldCount trường ($requiredFieldCount bắt buộc). '
              'Dữ liệu đã nhập trên sản phẩm sẽ được giữ lại. '
              'Nhóm sẽ không hiển thị khi tạo/sửa sản phẩm mới.',
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
                    key: const Key('btn_deactivate_group_cancel'),
                    label: 'Huỷ',
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_deactivate_group_confirm'),
                    label: 'Tạm tắt',
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: VButtonVariant.danger,
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
