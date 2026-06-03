import 'package:flutter/material.dart';
import '../../tokens/v_spacing.dart';
import '../../tokens/v_radius.dart';
import '../../tokens/v_typography.dart';
import '../atoms/v_button.dart';
import '../../utils/v_context_extensions.dart';

class VConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String actionLabel;
  final bool isDestructive;
  final VoidCallback onAction;

  const VConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.actionLabel,
    this.isDestructive = false,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.sheet),
      ),
      backgroundColor: dynamicColors.surface,
      elevation: 24, // Matches elevation level 4 (Modal/Bottom sheet)
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: VTypography.headingH3.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Text(
              message,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VButton(
                  label: cancelLabel,
                  variant: VButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: VSpacing.space2),
                VButton(
                  label: actionLabel,
                  variant: isDestructive ? VButtonVariant.danger : VButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAction();
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

Future<void> showVConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String actionLabel,
  bool isDestructive = false,
  required VoidCallback onAction,
}) {
  return showDialog(
    context: context,
    builder: (context) => VConfirmDialog(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      actionLabel: actionLabel,
      isDestructive: isDestructive,
      onAction: onAction,
    ),
  );
}
