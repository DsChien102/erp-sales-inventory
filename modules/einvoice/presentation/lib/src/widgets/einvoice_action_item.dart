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
///   Whether **sibling** actions are disabled is sheet policy (e.g. PostIssue
///   official-view loading disables siblings; SG-06 keeps the other document
///   action normal).
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

    final titleColor = isInteractive ? colors.textPrimary : colors.textMuted;
    final subtitleColor =
        isInteractive ? colors.textSecondary : colors.textMuted;
    final effectiveIconColor =
        isInteractive ? colors.textSecondary : colors.textMuted;
    final effectiveIconBg =
        isInteractive ? colors.surfaceAlt : colors.disabledBg;
    final cardBg = isInteractive ? colors.surface : colors.disabledBg;
    final chevronColor = isInteractive ? colors.textMuted : colors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: BorderSide(color: colors.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isInteractive ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIconBox(
                  icon: icon,
                  size: 44,
                  iconSize: 22,
                  isCircular: true,
                  backgroundColor: effectiveIconBg,
                  iconColor: effectiveIconColor,
                ),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: titleColor,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        supportingText,
                        variant: VTextVariant.bodySmall,
                        color: subtitleColor,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                else
                  VIcon(
                    icon: VIcons.chevronRight,
                    color: chevronColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
