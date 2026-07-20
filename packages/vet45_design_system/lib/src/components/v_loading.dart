import 'package:flutter/material.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';

class VLoading extends StatelessWidget {
  final String? title;
  final String? description;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticLabel;

  const VLoading({
    super.key,
    this.title,
    this.description,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final spinnerColor = color ?? dynamicColors.success;

    final spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
      ),
    );

    if (title == null && description == null) {
      return Semantics(
        label: semanticLabel ?? 'Đang tải...',
        child: spinner,
      );
    }

    return Semantics(
      label: semanticLabel ?? 'Đang tải...',
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          spinner,
          if (title != null) ...[
            const VGap.md(),
            VText(
              title!,
              style: VTypography.bodyDefault.copyWith(
                fontWeight: FontWeight.w600,
                color: dynamicColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (description != null) ...[
            const VGap.xs(),
            VText(
              description!,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return PopScope(
          canPop: barrierDismissible,
          child: Dialog(
            backgroundColor: context.vColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VRadius.r16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space6,
                vertical: VSpacing.space8,
              ),
              child: VLoading(
                title: title,
                description: description,
              ),
            ),
          ),
        );
      },
    );
  }
}
