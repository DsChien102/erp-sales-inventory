import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space4,
                VSpacing.space2,
                VSpacing.space4,
                VSpacing.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VButton(
                    key: const Key('btn_skip'),
                    label: 'Bỏ qua',
                    variant: VButtonVariant.ghost,
                    foregroundColor: colors.primary,
                    onPressed: onSkip,
                  ),
                  VButton(
                    key: const Key('btn_next'),
                    label: 'Tiếp',
                    onPressed: onNext,
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
        iconData: Icons.expand_less,
        size: 20,
        color: colors.textSecondary,
      );
    }
    if (isCompleted) {
      return VIcon(
        iconData: Icons.check_circle,
        size: 18,
        color: colors.primary,
      );
    }
    return VIcon(
      iconData: Icons.expand_more,
      size: 20,
      color: colors.textSecondary,
    );
  }
}
