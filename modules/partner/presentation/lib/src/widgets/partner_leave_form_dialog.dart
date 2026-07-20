import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

Future<void> showPartnerLeaveFormDialog({
  required BuildContext context,
  required VoidCallback onLeave,
}) {
  return showVBottomSheet<void>(
    context: context,
    title: 'Rời khỏi màn hình?',
    child: _PartnerLeaveFormSheet(onLeave: onLeave),
  );
}

class _PartnerLeaveFormSheet extends StatelessWidget {
  const _PartnerLeaveFormSheet({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space3,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Những thay đổi chưa lưu sẽ bị mất.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Ở lại chỉnh sửa',
                    variant: VButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    label: 'Rời khỏi',
                    variant: VButtonVariant.danger,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLeave();
                    },
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
