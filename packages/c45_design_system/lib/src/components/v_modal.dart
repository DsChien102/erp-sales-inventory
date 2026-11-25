import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_button.dart';

class VConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String actionLabel;
  final bool isDestructive;
  final VoidCallback onAction;
  final VComponentTone? tone;
  final String? semanticLabel;

  const VConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.actionLabel,
    this.isDestructive = false,
    required this.onAction,
    this.tone,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? title,
        child: Dialog(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.sheet),
          ),
          backgroundColor: dynamicColors.surface,
          elevation: 24,
          child: Padding(
            key: const Key('v-confirm-dialog-body'),
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width >= 1024 ? VSpacing.space6 : VSpacing.space5,
            ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: VSpacing.space2,
                    runSpacing: VSpacing.space2,
                    children: [
                      VButton(
                        label: cancelLabel,
                        variant: VButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      VButton(
                        label: actionLabel,
                        variant: VButtonVariant.primary,
                        tone: isDestructive ? VComponentTone.danger : tone,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onAction();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  VComponentTone? tone,
  String? semanticLabel,
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
      tone: tone,
      semanticLabel: semanticLabel,
    ),
  );
}
