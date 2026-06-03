import 'package:flutter/material.dart';
import '../../tokens/v_radius.dart';
import '../../tokens/v_spacing.dart';
import '../../tokens/v_typography.dart';
import '../../utils/v_context_extensions.dart';

class VBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;

  const VBottomSheet({
    super.key,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
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
          // Drag handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: VSpacing.space2),
              decoration: BoxDecoration(
                color: dynamicColors.borderStrong,
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
          Flexible(child: child),
        ],
      ),
    );
  }
}

Future<T?> showVBottomSheet<T>({
  required BuildContext context,
  String? title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => VBottomSheet(
      title: title,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ),
  );
}
