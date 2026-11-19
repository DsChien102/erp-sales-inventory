import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'partner_section_shell.dart';

class PartnerFormSection extends StatelessWidget {
  const PartnerFormSection({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.isCompleted,
    required this.onTap,
    required this.onSkip,
    required this.onNext,
    required this.child,
    this.summary,
    this.expandedTrailingText,
    this.showActions = true,
  });

  final String title;
  final bool isExpanded;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final Widget child;
  final String? summary;
  final String? expandedTrailingText;

  /// When false, expanded body has no «Bỏ qua» / «Tiếp» footer (e.g. note).
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return PartnerSectionShell(
      child: Column(
        children: [
          PartnerSectionHeader(
            title: title,
            trailingText: isExpanded ? expandedTrailingText : summary,
            trailingIcon: _trailingIcon(colors),
            onTap: onTap,
          ),
          if (isExpanded) ...[
            child,
            if (showActions)
              VPagePadding(
                vertical: VSpacing.space2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VButton(
                      key: const Key('btn_skip'),
                      label: 'Bỏ qua',
                      variant: VButtonVariant.tertiary,
                      foregroundColor: colors.primary,
                      onPressed: onSkip,
                    ),
                    SizedBox(
                      width: 112,
                      child: VButton(
                        key: const Key('btn_next'),
                        label: 'Tiếp',
                        size: VButtonSize.small,
                        fullWidth: true,
                        onPressed: onNext,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _trailingIcon(VColorScheme colors) {
    if (isExpanded) {
      return VIcon(
        icon: VIcons.expandLess,
        size: 20,
        color: colors.textSecondary,
      );
    }
    if (isCompleted) {
      return VIcon(
        icon: VIcons.success,
        size: 20,
        color: colors.primary,
      );
    }
    return VIcon(
      icon: VIcons.expandMore,
      size: 20,
      color: colors.textSecondary,
    );
  }
}
