import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../support/order_einvoice_copy.dart';

/// Full-screen result shown when E-Invoice configuration is incomplete.
///
/// Implements SG02-D01.
class ConfigurationBlockerResult extends StatelessWidget {
  const ConfigurationBlockerResult({
    super.key,
    this.onOpenSettings,
    this.onBack,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      title: OrderEInvoiceCopy.blockerPageTitle,
      leading: IconButton(
        icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VIconBox(
                icon: VIcons.warning,
                size: 64,
                iconSize: 32,
                isCircular: true,
                backgroundColor: colors.warningBg,
                iconColor: colors.warning,
              ),
              const VGap.xl(),
              VText(
                OrderEInvoiceCopy.configBlockerTitle,
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const VGap.sm(),
              VText(
                OrderEInvoiceCopy.configBlockerDescription,
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.lg(),
              VButton(
                label: OrderEInvoiceCopy.configBlockerAction,
                variant: VButtonVariant.tertiary,
                foregroundColor: colors.primary,
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
