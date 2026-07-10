import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailingText != null || trailingIcon != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (trailingText != null && trailingIcon != null)
                  const SizedBox(width: VSpacing.space2),
                if (trailingIcon != null) trailingIcon!,
              ],
            ),
        ],
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
