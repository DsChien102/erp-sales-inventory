import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom sheet xác nhận thoát form khi còn thay đổi chưa lưu.
class UnsavedChangesConfirmSheet extends StatelessWidget {
  const UnsavedChangesConfirmSheet({super.key});

  /// Trả về `true` nếu người dùng chọn thoát.
  static Future<bool> show(BuildContext context) async {
    final result = await showVBottomSheet<bool>(
      context: context,
      title: 'Thoát mà không lưu?',
      child: const UnsavedChangesConfirmSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thay đổi chưa lưu sẽ bị mất.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_unsaved_stay'),
                    label: 'Ở lại',
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: VButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    key: const Key('btn_unsaved_leave'),
                    label: 'Thoát',
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
