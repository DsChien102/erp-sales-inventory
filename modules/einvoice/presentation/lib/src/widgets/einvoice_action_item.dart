import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Internal reusable action-item anatomy for E-Invoice action sheets.
///
/// Shared between [PreIssueEInvoiceActionSheet],
/// [PostIssueEInvoiceActionSheet], and [InvoiceDocumentsActionSheet].
///
/// Contract:
/// - Enabled: normal icon/text/chevron treatment.
/// - Disabled: neutral100 background, muted icon/text/chevron. Chevron remains.
/// - Loading: chevron replaced by primary spinner; this row is non-interactive.
///   Whether **sibling** actions are disabled is sheet policy (PostIssue
///   official-view and SG-06 document download disable siblings).
/// - Callers must set [enabled] false (and omit [onTap]) when the item's
///   active status badge is [VBadgeStatus.processing] — see
///   `EInvoiceStatusInteraction`.
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
              SizedBox(
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
