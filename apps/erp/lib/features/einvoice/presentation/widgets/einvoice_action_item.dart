import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// App-owned action-item anatomy for post-issued E-Invoice sheets (TH-08 S4).
///
/// Contract:
/// - Enabled: normal icon/text/chevron treatment.
/// - Disabled: non-interactive; chevron remains.
/// - Loading: chevron replaced by primary spinner; this row is non-interactive.
///   Sibling disable policy belongs to the owning sheet (SG-06 / post-issue).
class EInvoiceActionItem extends StatelessWidget {
  const EInvoiceActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.supportingText,
    this.badge,
    this.enabled = true,
    this.loading = false,
    this.onTap,
  });

  final VIcons icon;
  final String title;
  final String supportingText;
  final Widget? badge;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isInteractive = enabled && !loading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: VCard(
        enabled: isInteractive,
        onTap: isInteractive ? onTap : null,
        child: Row(
          children: [
            VIcon(
              icon: icon,
              size: 22,
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.xs(),
                  VText(
                    supportingText,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const VGap.horizontalSm(),
              badge!,
            ],
            const VGap.horizontalSm(),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: VLoading(
                  strokeWidth: 2,
                ),
              )
            else
              VIcon(
                icon: VIcons.chevronRight,
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
