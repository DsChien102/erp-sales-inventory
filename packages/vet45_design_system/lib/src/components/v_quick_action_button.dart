import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

class VQuickActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const VQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.r16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: VSpacing.space2,
          horizontal: VSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: dynamicColors.surface,
          borderRadius: BorderRadius.circular(VRadius.r16),
          border: Border.all(color: dynamicColors.borderDefault),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: dynamicColors.surfaceBrand,
                    borderRadius: BorderRadius.circular(VRadius.r12),
                  ),
                  alignment: Alignment.center,
                  child: IconTheme(
                    data: IconThemeData(color: dynamicColors.primary, size: 18),
                    child: icon,
                  ),
                ),
                const SizedBox(height: VSpacing.space2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    label,
                    style: VTypography.caption.copyWith(
                      color: dynamicColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
