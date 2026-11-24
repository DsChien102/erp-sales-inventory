import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/einvoice/data/models.dart';

import '../support/einvoice_status_interaction.dart';
import '../support/order_einvoice_copy.dart';

/// Contextual row for E-Invoice status within Theme 05 source screens.
///
/// Implements SG02-R01 (Chi tiết đơn hàng) and SG02-R02 (Kết quả bán hàng),
/// and SG03-R01/R02/R03 issuance presentation on the same shared widget.
///
/// [isBuyerNotReady] drives helperText (readiness). [projection.issuanceDisplayState]
/// drives the trailing VBadge (issuance lifecycle).
///
/// When issuance is [IssuanceDisplayState.processing], the row ignores [onTap]
/// (see [EInvoiceStatusInteraction]) while preserving row and badge visuals.
class OrderEInvoiceRow extends StatelessWidget {
  const OrderEInvoiceRow({
    super.key,
    required this.projection,
    this.isBuyerNotReady = false,
    this.onTap,
  });

  final OrderInvoiceProjectionDto projection;
  final bool isBuyerNotReady;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final effectiveOnTap =
        EInvoiceStatusInteraction.allowsTapForIssuance(
          projection.issuanceDisplayState,
        )
        ? onTap
        : null;

    return VCard(
      onTap: effectiveOnTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          VIcon(
            icon: VIcons.fileCheck,
            color: colors.textPrimary,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  OrderEInvoiceCopy.rowTitle,
                  variant: VTextVariant.headingH4,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  _helperText,
                  variant: VTextVariant.bodySmall,
                  color: _helperColor(context),
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          _buildTrailing(context),
        ],
      ),
    );
  }

  String get _helperText =>
      isBuyerNotReady ? OrderEInvoiceCopy.rowHelperNotReady : OrderEInvoiceCopy.rowHelperManage;

  Color _helperColor(BuildContext context) {
    final colors = context.vColors;
    return isBuyerNotReady ? colors.warning : colors.textSecondary;
  }

  Widget _buildTrailing(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _badgeForState,
        const VGap.horizontalSm(),
        VIcon(
          icon: VIcons.chevronRight,
          color: colors.textMuted,
          size: 20,
        ),
      ],
    );
  }

  VBadge get _badgeForState {
    switch (projection.issuanceDisplayState) {
      case IssuanceDisplayState.notIssued:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeNotIssued,
          tone: VComponentTone.neutral,
        );
      case IssuanceDisplayState.processing:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeProcessing,
          tone: VComponentTone.primary,
        );
      case IssuanceDisplayState.issued:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeIssued,
          tone: VComponentTone.success,
        );
      case IssuanceDisplayState.failed:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeIssueFailed,
          tone: VComponentTone.danger,
        );
    }
  }
}
