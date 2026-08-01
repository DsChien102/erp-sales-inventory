import 'package:flutter/material.dart';

import '../patterns/v_gap.dart';
import 'v_button.dart';

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
              for (var c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const VGap.horizontalSm(),
                Expanded(child: _buildKey(rows[r][c])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) return const SizedBox.shrink();
    return VButton(
      label: key,
      variant: VButtonVariant.outline,
      size: VButtonSize.large,
      fullWidth: true,
      onPressed: () => key == '⌫' ? onBackspace() : onKey(key),
    );
  }
}
