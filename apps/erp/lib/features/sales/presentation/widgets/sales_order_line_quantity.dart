import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Compact ± quantity controls for sales order lines (44px hit targets).
class SalesOrderLineQuantityControls extends StatelessWidget {
  const SalesOrderLineQuantityControls({
    super.key,
    required this.quantity,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
    this.onQuantityTap,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback? onQuantityTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HitControl(
          onTap: enabled ? onDecrement : null,
          child: _MiniChip(
            child: VText(
              '−',
              variant: VTextVariant.headingH4,
              color: enabled ? colors.textPrimary : colors.textMuted,
              style: const TextStyle(fontSize: 16, height: 22 / 16),
            ),
          ),
        ),
        _HitControl(
          onTap: enabled ? (onQuantityTap ?? () {}) : null,
          child: Container(
            width: 30,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VRadius.r8),
              border: Border.all(color: colors.borderDefault),
            ),
            child: VText(
              '$quantity',
              variant: VTextVariant.bodySmallMono,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 20 / 14,
              ),
            ),
          ),
        ),
        _HitControl(
          onTap: enabled ? onIncrement : null,
          child: _MiniChip(
            child: VIcon(
              icon: VIcons.add,
              size: 16,
              color: enabled ? colors.textPrimary : colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class SalesOrderLineSwipeIconAction extends StatelessWidget {
  const SalesOrderLineSwipeIconAction({
    super.key,
    required this.width,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.semanticLabel,
    this.onTap,
  });

  final double width;
  final Color background;
  final VIcons icon;
  final Color iconColor;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Center(
          child: Semantics(
            button: true,
            label: semanticLabel,
            child: VIcon(icon: icon, size: 20, color: iconColor),
          ),
        ),
      ),
    ),
  );
}

class _HitControl extends StatelessWidget {
  const _HitControl({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: VSpacing.controlCompact,
    height: VSpacing.controlCompact,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.r8),
      child: Center(child: child),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
      ),
      child: child,
    );
  }
}
