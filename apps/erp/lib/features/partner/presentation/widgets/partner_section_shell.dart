import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class PartnerSectionShell extends StatelessWidget {
  const PartnerSectionShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: child,
    );
  }
}

class PartnerSectionHeader extends StatelessWidget {
  const PartnerSectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.trailingIcon,
    this.onTap,
  });

  final String title;
  final String? trailingText;
  final Widget? trailingIcon;
  final VoidCallback? onTap;

  /// Fixed trailing icon slot so chevron/lock align across section rows.
  static const double _iconSlot = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cap summary width so title stays readable; icon stays flush right.
          final summaryMaxWidth = constraints.maxWidth * 0.45;
          return Row(
            children: [
              Expanded(
                child: VText(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: VSpacing.space2),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: summaryMaxWidth),
                  child: VText(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: VSpacing.space2),
                SizedBox(
                  width: _iconSlot,
                  height: _iconSlot,
                  child: Center(child: trailingIcon),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: content,
    );
  }
}
