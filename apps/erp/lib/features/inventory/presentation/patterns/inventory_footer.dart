import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'inventory_layout.dart';

class InventoryFooterAction {
  const InventoryFooterAction({
    required this.label,
    this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
}

class InventoryFooter extends StatelessWidget {
  const InventoryFooter({
    super.key,
    required this.actions,
  });

  final List<InventoryFooterAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final isWide = inventoryIsWide(context);

    // Web: hàng nút căn phải (từ 3 nút: tự xuống dòng khi hẹp)
    if (isWide && actions.length >= 3) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: VSpacing.space3,
        runSpacing: VSpacing.space2,
        children: [for (final a in actions) _buildButton(a)],
      );
    }
    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            _buildButton(actions[i]),
            if (i < actions.length - 1) const SizedBox(width: VSpacing.space3),
          ],
        ],
      );
    }

    // iPhone:
    // 1 nút: full
    if (actions.length == 1) {
      return _buildButton(actions.first, fullWidth: true);
    }

    // 3 nút trở lên: xếp dọc, nút chính ở trên, giữ thứ tự còn lại
    if (actions.length >= 3) {
      final ordered = [
        ...actions.where((a) => a.primary),
        ...actions.where((a) => !a.primary),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            _buildButton(ordered[i], fullWidth: true),
            if (i < ordered.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }

    // 2 nút và có nhãn > 17 ký tự: xếp dọc, nút chính ở trên
    final hasLongLabel = actions.any((a) => a.label.length > 17);
    if (actions.length == 2 && hasLongLabel) {
      final primaryAction = actions.firstWhere((a) => a.primary, orElse: () => actions.last);
      final secondaryAction = actions.firstWhere((a) => !a.primary, orElse: () => actions.first);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(primaryAction, fullWidth: true),
          const SizedBox(height: VSpacing.space2),
          _buildButton(secondaryAction, fullWidth: true),
        ],
      );
    }

    // 2 nút: hàng ngang Phụ | Chính
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _buildButton(actions[i], fullWidth: true),
          ),
          if (i < actions.length - 1) const SizedBox(width: VSpacing.space2),
        ],
      ],
    );
  }

  Widget _buildButton(InventoryFooterAction action, {bool fullWidth = false}) {
    return VButton(
      label: action.label,
      variant: action.primary ? VButtonVariant.primary : VButtonVariant.secondary,
      onPressed: action.onPressed,
      fullWidth: fullWidth,
    );
  }
}

class InventoryReasonFooter extends StatelessWidget {
  const InventoryReasonFooter({
    super.key,
    required this.label,
    this.onPressed,
    this.reason = '',
    this.note = '',
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String reason;
  final String note;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final message = onPressed == null ? reason : note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space2),
            child: Text(
              message,
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        VButton(
          label: label,
          tone: danger ? VComponentTone.danger : null,
          onPressed: onPressed,
          fullWidth: true,
        ),
      ],
    );
  }
}
