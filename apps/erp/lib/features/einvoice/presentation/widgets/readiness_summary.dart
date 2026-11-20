import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/presentation/support/einvoice_configuration_overview_copy.dart';

class ReadinessSummary extends StatelessWidget {
  const ReadinessSummary({
    super.key,
    required this.isReady,
    required this.blockerCount,
    this.onCompleteTap,
  });

  final bool isReady;
  final int blockerCount;
  final VoidCallback? onCompleteTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final background = isReady ? colors.successBg : colors.warningBg;
    final borderColor = isReady ? colors.success : colors.warning;
    final eyebrowColor = isReady ? colors.success : colors.warning;

    return VCard(
      backgroundColor: background,
      border: VBorders.all(borderColor),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isReady) ...[
            VText(
              EInvoiceConfigurationOverviewCopy.notReadyEyebrow,
              variant: VTextVariant.bodySmall,
              color: eyebrowColor,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const VGap.xs(),
          ],
          VText(
            isReady
                ? EInvoiceConfigurationOverviewCopy.readyTitle
                : EInvoiceConfigurationOverviewCopy.notReadyTitle,
            variant: VTextVariant.headingH3,
            color: colors.textPrimary,
          ),
          const VGap.xs(),
          VText(
            isReady
                ? EInvoiceConfigurationOverviewCopy.readyDescription
                : EInvoiceConfigurationOverviewCopy.notReadyDescription(
                    blockerCount,
                  ),
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (!isReady) ...[
            const VGap.sm(),
            Align(
              alignment: Alignment.centerRight,
              child: _ReadinessCompleteAction(onTap: onCompleteTap),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessCompleteAction extends StatelessWidget {
  const _ReadinessCompleteAction({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space1,
            vertical: VSpacing.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VText(
                EInvoiceConfigurationOverviewCopy.completeActionLabel,
                variant: VTextVariant.bodySmall,
                color: colors.primary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const VGap.horizontalXs(),
              VIcon(
                icon: VIcons.chevronRight,
                size: 16,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
