import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../formatters/price_rule_import_issue_formatter.dart';

/// Chip thống kê preview import.
class PriceRuleImportStatChip extends StatelessWidget {
  const PriceRuleImportStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: VCard(
        padding: const EdgeInsets.all(VSpacing.space2),
        child: Column(
          children: [
            VText('$value', variant: VTextVariant.headingH4Mono, color: color),
            VText(
              label,
              variant: VTextVariant.caption,
              color: context.vColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile một dòng preview import.
class PriceRuleImportRowTile extends StatelessWidget {
  const PriceRuleImportRowTile({super.key, required this.row});

  final CustomerPriceRuleImportRowPreviewDto row;

  @override
  Widget build(BuildContext context) {
    final custName =
        row.customerSnapshot?['displayName'] ?? row.customerId ?? '';
    final prodName =
        row.productSnapshot?['productName'] ?? row.productReferenceId ?? '';
    final colors = context.vColors;
    final tone = switch (row.status) {
      CustomerPriceRuleImportRowStatus.valid => colors.success,
      CustomerPriceRuleImportRowStatus.warning => colors.warning,
      CustomerPriceRuleImportRowStatus.error => colors.danger,
      _ => colors.textMuted,
    };
    final errorMessages = row.errorCodes
        .map((code) => PriceRuleImportIssueFormatter.errorMessage(code, row))
        .toList(growable: false);
    final warningMessages = row.warningCodes
        .map((code) => PriceRuleImportIssueFormatter.warningMessage(code, row))
        .toList(growable: false);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: VSpacing.space1),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Dòng ${row.rowNumber}: $custName · $prodName',
                  variant: VTextVariant.bodySmallMono,
                ),
                if (errorMessages.isNotEmpty || warningMessages.isNotEmpty)
                  const VGap.xs(),
                for (final message in errorMessages)
                  VText(
                    message,
                    variant: VTextVariant.bodySmall,
                    color: colors.danger,
                  ),
                for (final message in warningMessages)
                  VText(
                    message,
                    variant: VTextVariant.bodySmall,
                    color: colors.warning,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng label/value trong tóm tắt confirm/result.
class PriceRuleImportConfirmRow extends StatelessWidget {
  const PriceRuleImportConfirmRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
          ),
          VText(value, variant: VTextVariant.monoNumeric, color: color),
        ],
      ),
    );
  }
}

/// Bullet lưu ý bước 1.
class PriceRuleImportBullet extends StatelessWidget {
  const PriceRuleImportBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space1),
      child: VText(
        '• $text',
        variant: VTextVariant.bodySmall,
        color: context.vColors.textSecondary,
      ),
    );
  }
}
