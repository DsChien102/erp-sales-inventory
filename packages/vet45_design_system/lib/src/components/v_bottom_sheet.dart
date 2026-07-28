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

  const VBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.tone,
    this.semanticLabel,
  });

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
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
              // Avoid Flexible inside MainAxisSize.min (unbounded flex → huge overflow).
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
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => VBottomSheet(
      title: title,
      tone: tone,
      semanticLabel: semanticLabel,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ),
  );
}
