import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Hàng nhãn + giá trị nổi bật dùng chung cho Sales: nền tint theo [tone],
/// nhãn bên trái, giá trị (đã format sẵn) bên phải.
///
/// Không format tiền — caller truyền [value] dạng string hiển thị.
class SalesLabelHighlightRow extends StatelessWidget {
  const SalesLabelHighlightRow({
    super.key,
    required this.label,
    required this.value,
    this.tone = VComponentTone.primary,
    this.valueKey,
    this.labelVariant = VTextVariant.bodyDefault,
    this.valueVariant = VTextVariant.bodyDefaultMono,
    this.emphasizeLabel = true,
    this.padding = const EdgeInsets.all(VSpacing.space3),
    this.backgroundColor,
  });

  final String label;
  final String value;

  /// Quyết định nền tint + màu giá trị.
  final VComponentTone tone;

  /// Key cho `VText` giá trị (dùng trong widget test).
  final Key? valueKey;

  /// Typography nhãn bên trái (vd. `headingH4` khi giá trị dùng `headingH4Mono`).
  final VTextVariant labelVariant;

  /// Typography giá trị bên phải (vd. `headingH4Mono`).
  final VTextVariant valueVariant;

  /// `true`: nhãn cùng màu tone; `false`: nhãn dùng `textPrimary`.
  final bool emphasizeLabel;

  final EdgeInsetsGeometry padding;

  final Color? backgroundColor;

  Color _toneForeground(VColorScheme colors) {
    return switch (tone) {
      VComponentTone.primary => colors.textBrand,
      VComponentTone.success => colors.success,
      VComponentTone.warning => colors.warning,
      VComponentTone.danger => colors.danger,
      VComponentTone.info => colors.info,
      VComponentTone.neutral => colors.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final foreground = _toneForeground(colors);

    return VCard(
      tone: tone,
      borderRadius: VRadius.input,
      border: const Border(),
      backgroundColor: backgroundColor,
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VText(
            label,
            variant: labelVariant,
            color: emphasizeLabel ? foreground : colors.textPrimary,
          ),
          VText(
            value,
            key: valueKey,
            variant: valueVariant,
            color: foreground,
          ),
        ],
      ),
    );
  }
}
