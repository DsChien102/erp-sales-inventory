import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import 'price_rule_import_shared.dart';

/// SG-04 — Kết quả sau khi import.
class PriceRuleImportResultView extends StatelessWidget {
  const PriceRuleImportResultView({
    super.key,
    required this.result,
    this.onFinish,
  });

  final CustomerPriceRuleImportResultDto result;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    final isSuccess = batch.failedRows == 0;
    final colors = context.vColors;

    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VGap.xl(),
          Center(
            child: VIconBox(
              icon: isSuccess ? VIcons.success : VIcons.warning,
              size: 72,
              iconSize: 36,
              isCircular: true,
              tone: isSuccess ? VComponentTone.success : VComponentTone.warning,
            ),
          ),
          const VGap.md(),
          VText(
            isSuccess ? 'Import thành công!' : 'Import hoàn tất (có cảnh báo)',
            variant: VTextVariant.headingH3,
            textAlign: TextAlign.center,
          ),
          const VGap.sm(),
          VText(
            'Đã import ${batch.importedRows} dòng giá riêng.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const VGap.lg(),
          VCard(
            padding: const EdgeInsets.all(VSpacing.space3),
            child: Column(
              children: [
                PriceRuleImportConfirmRow(
                  label: 'Tổng dòng',
                  value: '${batch.totalRows}',
                ),
                PriceRuleImportConfirmRow(
                  label: 'Import thành công',
                  value: '${batch.importedRows}',
                  color: colors.success,
                ),
                PriceRuleImportConfirmRow(
                  label: 'Bỏ qua',
                  value: '${batch.skippedRows}',
                  color: colors.warning,
                ),
                PriceRuleImportConfirmRow(
                  label: 'Lỗi',
                  value: '${batch.failedRows}',
                  color: colors.danger,
                ),
              ],
            ),
          ),
          const Spacer(),
          VButton(
            label: 'Hoàn tất',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: onFinish ?? () => Navigator.of(context).pop(),
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}
