import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../formatters/price_rule_import_issue_formatter.dart';
import 'price_rule_import_shared.dart';

/// D-03 — Bottom sheet chi tiết dòng cảnh báo / lỗi import.
Future<void> showPriceRuleImportIssueDetailSheet({
  required BuildContext context,
  required CustomerPriceRuleImportRowPreviewDto row,
}) {
  final isError = row.status == CustomerPriceRuleImportRowStatus.error;
  return showVBottomSheet<void>(
    context: context,
    title: isError ? 'Chi tiết lỗi' : 'Chi tiết cảnh báo',
    child: PriceRuleImportIssueDetailSheet(row: row),
  );
}

class PriceRuleImportIssueDetailSheet extends StatelessWidget {
  const PriceRuleImportIssueDetailSheet({super.key, required this.row});

  final CustomerPriceRuleImportRowPreviewDto row;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isError = row.status == CustomerPriceRuleImportRowStatus.error;
    final tone = isError ? VComponentTone.danger : VComponentTone.warning;
    final messages = <String>[
      ...row.errorCodes.map(
        (code) => PriceRuleImportIssueFormatter.errorMessage(code, row),
      ),
      ...row.warningCodes.map(
        (code) => PriceRuleImportIssueFormatter.warningMessage(code, row),
      ),
    ];

    return VPagePadding(
      applyBottomSafeArea: true,
      vertical: VSpacing.space3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIconBox(
                icon: isError ? VIcons.error : VIcons.warning,
                size: VSpacing.space10,
                iconSize: VSpacing.space5,
                isCircular: true,
                tone: tone,
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VText(
                  'Dòng ${row.rowNumber}',
                  variant: VTextVariant.headingH4,
                ),
              ),
            ],
          ),
          const VGap.md(),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailLine(
                  label: 'Khách hàng',
                  value: PriceRuleImportRowLabels.customer(row),
                ),
                const VGap.xs(),
                _DetailLine(
                  label: 'Sản phẩm',
                  value: PriceRuleImportRowLabels.product(row),
                ),
                const VGap.xs(),
                _DetailLine(
                  label: 'Đơn vị',
                  value: PriceRuleImportRowLabels.unit(row),
                ),
                const VGap.xs(),
                _DetailLine(
                  label: 'Giá',
                  value: PriceRuleImportRowLabels.price(row),
                ),
              ],
            ),
          ),
          if (messages.isNotEmpty) ...[
            const VGap.md(),
            VCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < messages.length; i++) ...[
                    if (i > 0) const VGap.sm(),
                    VText(
                      messages[i],
                      variant: VTextVariant.bodyDefault,
                      color: isError ? colors.danger : colors.warning,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const VGap.lg(),
          VButton(
            label: 'Đã hiểu',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textMuted,
        ),
        const VGap.horizontalSm(),
        Flexible(
          child: VText(
            value,
            variant: VTextVariant.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
