import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'sales_order_line_quantity.dart';
import 'sales_product_thumbnail.dart';
import 'sales_special_price_banner.dart';

/// Compact editable order line with optional swipe actions (discount / delete).
class SalesOrderLineRow extends StatelessWidget {
  const SalesOrderLineRow({
    super.key,
    required this.productName,
    required this.unitPriceLabel,
    required this.quantity,
    required this.onQuantityChanged,
    this.image,
    this.showSpecialPriceBadge = false,
    this.warningText,
    this.minQuantity = 0,
    this.maxQuantity = 9999,
    this.onDiscount,
    this.onDelete,
    this.onTap,
    this.onQuantityTap,
    this.enabled = true,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
    this.revealActions = false,
  });

  final String productName;
  final String unitPriceLabel;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final Widget? image;
  final bool showSpecialPriceBadge;
  final String? warningText;
  final int minQuantity;
  final int maxQuantity;
  final VoidCallback? onDiscount;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onQuantityTap;
  final bool enabled;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;
  final bool revealActions;

  static const double actionWidth = 58;
  static const double actionsTotalWidth = actionWidth * 2;

  bool get _hasActions => onDiscount != null || onDelete != null;

  String? get _warning {
    final text = warningText?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final warning = _warning;
    final warningWeight = switch (emphasis) {
      VComponentEmphasis.strong => FontWeight.w700,
      _ => FontWeight.w600,
    };
    final warningColor = switch (tone) {
      VComponentTone.danger => colors.danger,
      VComponentTone.info => colors.info,
      VComponentTone.success => colors.success,
      _ => colors.warning,
    };

    return Semantics(
      label: semanticLabel ?? productName,
      enabled: enabled,
      child: VSwipeReveal(
        enabled: enabled && _hasActions,
        actionExtent: _hasActions ? actionsTotalWidth : 0,
        initiallyRevealed: revealActions && _hasActions,
        clipBorderRadius: BorderRadius.zero,
        semanticActions: [
          if (onDiscount != null)
            VSwipeSemanticAction(label: 'Chiết khấu', onInvoke: onDiscount!),
          if (onDelete != null)
            VSwipeSemanticAction(label: 'Xóa', onInvoke: onDelete!),
        ],
        actionsBuilder: (context, close) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionSlot(
              callback: onDiscount,
              background: colors.successBg,
              icon: VIcons.tag,
              iconColor: colors.textBrand,
              label: 'Chiết khấu',
              enabled: enabled,
              close: close,
            ),
            _actionSlot(
              callback: onDelete,
              background: colors.dangerBg,
              icon: VIcons.delete,
              iconColor: colors.danger,
              label: 'Xóa',
              enabled: enabled,
              close: close,
            ),
          ],
        ),
        child: SalesSpecialPriceBanner(
          visible: showSpecialPriceBadge,
          child: Material(
            color: colors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: enabled ? onTap : null,
                              borderRadius: BorderRadius.circular(VRadius.r8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  image ?? const SalesProductThumbnail(),
                                  const VGap.horizontalSm(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        VText(
                                          productName,
                                          variant: VTextVariant.bodyDefault,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            height: 20 / 14,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                VText(
                                                  unitPriceLabel,
                                                  variant: VTextVariant.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  color: colors.textSecondary,
                                                ),
                                                if (warning != null) ...[
                                                  const VGap.xs(),
                                                  VText(
                                                    warning,
                                                    variant: VTextVariant.labelSmall,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    color: warningColor,
                                                    style: TextStyle(
                                                      fontWeight: warningWeight,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SalesOrderLineQuantityControls(
                                              quantity: quantity,
                                              enabled: enabled,
                                              onDecrement: () {
                                                if (!enabled || quantity <= minQuantity) {
                                                  return;
                                                }
                                                onQuantityChanged(quantity - 1);
                                              },
                                              onIncrement: () {
                                                if (!enabled || quantity >= maxQuantity) {
                                                  return;
                                                }
                                                onQuantityChanged(quantity + 1);
                                              },
                                              onQuantityTap: onQuantityTap,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionSlot({
    required VoidCallback? callback,
    required Color background,
    required VIcons icon,
    required Color iconColor,
    required String label,
    required bool enabled,
    required VoidCallback close,
  }) => SalesOrderLineSwipeIconAction(
    width: actionWidth,
    background: background,
    icon: icon,
    iconColor: iconColor,
    semanticLabel: label,
    onTap: enabled
        ? () {
            callback?.call();
            close();
          }
        : null,
  );
}
