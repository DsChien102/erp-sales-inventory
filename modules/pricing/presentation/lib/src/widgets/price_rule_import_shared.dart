import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../formatters/price_rule_import_issue_formatter.dart';

/// Chip thống kê preview import — label trên, số lớn dưới (design Kiểm tra).
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
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space2,
          vertical: VSpacing.space3,
        ),
        child: Column(
          children: [
            VText(
              label,
              variant: VTextVariant.caption,
              color: context.vColors.textMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const VGap.xs(),
            VText(
              '$value',
              variant: VTextVariant.headingH4Mono,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn hiển thị từ snapshot dòng import (camelCase hoặc snake_case).
abstract final class PriceRuleImportRowLabels {
  static String customer(CustomerPriceRuleImportRowPreviewDto row) =>
      _snap(row.customerSnapshot, const ['displayName', 'display_name']) ??
      row.customerId ??
      '—';

  static String product(CustomerPriceRuleImportRowPreviewDto row) =>
      _snap(row.productSnapshot, const [
        'productName',
        'product_name',
        'sku',
        'code',
      ]) ??
      row.productReferenceId ??
      '—';

  static String unit(CustomerPriceRuleImportRowPreviewDto row) =>
      _snap(row.unitSnapshot, const ['unitName', 'unit_name', 'name']) ?? '—';

  static String price(CustomerPriceRuleImportRowPreviewDto row) {
    final minor = row.normalizedPriceMinor;
    if (minor != null) return _formatMoney(minor);
    final raw = row.price?.trim();
    if (raw == null || raw.isEmpty) return '—';
    final parsed = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    return parsed == null ? raw : _formatMoney(parsed);
  }

  static String? _snap(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _formatMoney(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
}

/// Tile một dòng preview import (cảnh báo / lỗi).
class PriceRuleImportRowTile extends StatelessWidget {
  const PriceRuleImportRowTile({super.key, required this.row});

  final CustomerPriceRuleImportRowPreviewDto row;

  @override
  Widget build(BuildContext context) {
    final custName = PriceRuleImportRowLabels.customer(row);
    final prodName = PriceRuleImportRowLabels.product(row);
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

/// Bullet lưu ý bước 1 / kiểm tra nhanh.
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
