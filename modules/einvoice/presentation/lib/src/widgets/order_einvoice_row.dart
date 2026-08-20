import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../support/order_einvoice_copy.dart';

/// Contextual row for E-Invoice status within Theme 05 source screens.
///
/// Implements SG02-R01 (Chi tiết đơn hàng) and SG02-R02 (Kết quả bán hàng).
///
/// [isBuyerNotReady] drives helperText (readiness). [projection.issuanceDisplayState]
/// drives the trailing VBadge (issuance lifecycle).
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

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          VIconBox(
            icon: VIcons.fileCheck,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textSecondary,
            borderRadius: VRadius.r12,
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
      isBuyerNotReady
          ? OrderEInvoiceCopy.rowHelperNotReady
          : OrderEInvoiceCopy.rowHelperManage;

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
          color: colors.textSecondary,
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
          status: VBadgeStatus.draft,
          isSmall: true,
        );
      case IssuanceDisplayState.processing:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeProcessing,
          status: VBadgeStatus.processing,
          isSmall: true,
        );
      case IssuanceDisplayState.issued:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeIssued,
          status: VBadgeStatus.success,
          isSmall: true,
        );
      case IssuanceDisplayState.failed:
        return const VBadge(
          label: OrderEInvoiceCopy.badgeIssueFailed,
          status: VBadgeStatus.danger,
          isSmall: true,
        );
    }
  }
}
