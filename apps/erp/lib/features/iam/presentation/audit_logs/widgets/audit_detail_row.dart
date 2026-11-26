import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c45_design_system/design_system.dart';

/// Detail row that adapts to its value:
/// - short single-line → inline `label … value` (value right-aligned);
/// - long or multi-line → stacked, value full-width left-aligned below the
///   label (monospace when it is a copyable identifier so it stops wrapping
///   awkwardly right-aligned). [copyable] adds a copy-to-clipboard button.
class AuditDetailRow extends StatelessWidget {
  const AuditDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.copyValue,
    this.copyTooltip = 'Sao chép',
  });

  final String label;
  final String value;
  final bool copyable;
  final String? copyValue;
  final String copyTooltip;

  /// Values long enough to wrap (UUIDs, tracking ids) or already multi-line
  /// read far better stacked and left-aligned than squeezed to the right.
  bool get _isBlock => value.length > 24 || value.contains('\n');

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (_isBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: VText(
                  label,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                ),
              ),
              if (copyable)
                AuditCopyButton(
                  value: copyValue ?? value,
                  tooltip: copyTooltip,
                ),
            ],
          ),
          const VGap.xs(),
          VText(
            value,
            variant: VTextVariant.bodyDefault,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.4,
              fontFamily: copyable ? 'monospace' : null,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: VText(
                  value,
                  variant: VTextVariant.bodyDefault,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (copyable)
                AuditCopyButton(
                  value: copyValue ?? value,
                  tooltip: copyTooltip,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditCopyButton extends StatelessWidget {
  const AuditCopyButton({
    super.key,
    required this.value,
    required this.tooltip,
  });

  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return IconButton(
      icon: VIcon(
        icon: VIcons.clipboard,
        size: 18,
        color: colors.textBrand,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: VSpacing.minTouchTarget,
        height: VSpacing.minTouchTarget,
      ),
      tooltip: tooltip,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        VToast.show(
          context,
          title: 'Đã sao chép',
          message: 'Đã sao chép mã theo dõi.',
          type: VToastType.success,
        );
      },
    );
  }
}
