import 'package:flutter/material.dart';

import '../patterns/v_gap.dart';
import '../foundation/v_context_extensions.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';

/// Keypad mode for [VNumericKeypadSheet] / [VNumericKeypadGrid].
enum VNumericKeypadMode {
  /// Decimal entry when [allowDecimal] is true; bottom-left key is `.`.
  quantity,

  /// Integer VND entry; bottom-left key is `000` shortcut.
  money,
}

/// Key grid for [VNumericKeypadMode] (quantity / money).
class VNumericKeypadGrid extends StatelessWidget {
  const VNumericKeypadGrid({
    super.key,
    required this.mode,
    required this.allowDecimal,
    required this.onKey,
    required this.onBackspace,
  });

  final VNumericKeypadMode mode;
  final bool allowDecimal;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final bottomLeft = switch (mode) {
      VNumericKeypadMode.money => '000',
      VNumericKeypadMode.quantity => allowDecimal ? '.' : '',
    };

    final rows = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [bottomLeft, '0', '⌫'],
    ];

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const VGap.sm(),
          Row(
            children: [
              for (var c = 0; c < 3; c++) ...[
                if (c > 0) const VGap.horizontalSm(),
                Expanded(
                  child: _Key(
                    label: rows[r][c],
                    onTap: rows[r][c].isEmpty
                        ? null
                        : () => rows[r][c] == '⌫' ? onBackspace() : onKey(rows[r][c]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isSpecial = label == '000' || label == '⌫' || label == '.';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.card),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.card),
            border: VBorders.all(colors.borderDefault),
          ),
          child: VText(
            label,
            variant: isSpecial ? VTextVariant.headingH4 : VTextVariant.headingH2,
            style: TextStyle(
              fontSize: isSpecial ? 16 : 22,
              height: isSpecial ? 22 / 16 : 28 / 22,
            ),
          ),
        ),
      ),
    );
  }
}
