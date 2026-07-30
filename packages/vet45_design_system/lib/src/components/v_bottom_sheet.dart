import 'package:flutter/material.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

class VBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final VComponentTone? tone;
  final String? semanticLabel;

  /// Max height as a fraction of screen height. Defaults to 0.95.
  final double maxHeightFraction;

  const VBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.tone,
    this.semanticLabel,
    this.maxHeightFraction = 0.95,
  }) : assert(maxHeightFraction > 0 && maxHeightFraction <= 1);

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedTone = tone ?? VComponentTone.neutral;

    final handleColor = switch (resolvedTone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.borderStrong,
    };

    return Semantics(
      label: semanticLabel ?? title ?? 'Bottom sheet',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: dynamicColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: VSpacing.space2),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space2,
                  ),
                  child: Text(
                    title!,
                    style: VTypography.headingH3.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Divider(color: dynamicColors.borderDefault, height: 1),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showVBottomSheet<T>({
  required BuildContext context,
  String? title,
  required Widget child,
  VComponentTone? tone,
  String? semanticLabel,
  double maxHeightFraction = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => VBottomSheet(
      title: title,
      tone: tone,
      semanticLabel: semanticLabel,
      maxHeightFraction: maxHeightFraction,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ),
  );
}
