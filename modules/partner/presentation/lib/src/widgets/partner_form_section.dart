import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
  });

  final String title;
  final bool isExpanded;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final Widget child;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
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
                  if (!isExpanded && summary != null) ...[
                    Flexible(
                      child: Text(
                        summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space2),
                  ],
                  if (isCompleted)
                    VIcon(
                      iconData: Icons.check_circle,
                      size: 18,
                      color: colors.primary,
                    )
                  else
                    VIcon(
                      iconData: isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: colors.borderDefault),
            Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  const SizedBox(height: VSpacing.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VButton(
                        key: const Key('btn_skip'),
                        label: 'Bỏ qua',
                        variant: VButtonVariant.ghost,
                        onPressed: onSkip,
                      ),
                      VButton(
                        key: const Key('btn_next'),
                        label: 'Tiếp',
                        onPressed: onNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
