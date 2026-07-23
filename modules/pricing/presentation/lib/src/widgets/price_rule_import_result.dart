import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_state.dart';
import 'price_rule_import_shared.dart';

/// SG-04 D-05/D-06 — Kết quả sau khi import (success / partial / failed).
class PriceRuleImportResultView extends StatelessWidget {
  const PriceRuleImportResultView({
    super.key,
    required this.result,
    required this.outcome,
    this.onFinish,
    this.onViewValid,
    this.onViewWarnings,
    this.onViewErrors,
  });

  final CustomerPriceRuleImportResultDto result;
  final PriceRuleImportOutcome outcome;
  final VoidCallback? onFinish;
  final VoidCallback? onViewValid;
  final VoidCallback? onViewWarnings;
  final VoidCallback? onViewErrors;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    final colors = context.vColors;
    final (icon, tone, title, subtitle) = switch (outcome) {
      PriceRuleImportOutcome.success => (
        VIcons.success,
        VComponentTone.success,
        'Import thành công!',
        'Đã import ${batch.importedRows} dòng giá riêng.',
      ),
      PriceRuleImportOutcome.partial => (
        VIcons.warning,
        VComponentTone.warning,
        'Import một phần',
        'Đã import ${batch.importedRows} dòng. '
            'Một số dòng bị bỏ qua hoặc lỗi.',
      ),
      PriceRuleImportOutcome.failed => (
        VIcons.error,
        VComponentTone.danger,
        'Import thất bại',
        'Không có dòng nào được import. Vui lòng kiểm tra lại file.',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: VPagePadding(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VGap.xl(),
                  Center(
                    child: VIconBox(
                      icon: icon,
                      size: VSpacing.space18,
                      iconSize: VSpacing.space8 + VSpacing.space1,
                      isCircular: true,
                      tone: tone,
                    ),
                  ),
                  const VGap.md(),
                  VText(
                    title,
                    variant: VTextVariant.headingH3,
                    textAlign: TextAlign.center,
                  ),
                  const VGap.sm(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  const VGap.lg(),
                  VCard(
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
                  const VGap.md(),
                  VSection(
                    title: 'Chi tiết kết quả',
                    child: Column(
                      children: [
                        _ResultLinkTile(
                          label: 'Dữ liệu hợp lệ',
                          count: batch.validRows,
                          onTap: onViewValid,
                        ),
                        const VGap.xs(),
                        _ResultLinkTile(
                          label: 'Cảnh báo',
                          count: batch.warningRows,
                          onTap: onViewWarnings,
                        ),
                        const VGap.xs(),
                        _ResultLinkTile(
                          label: 'Lỗi',
                          count: batch.errorRows > 0
                              ? batch.errorRows
                              : batch.failedRows,
                          onTap: onViewErrors,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        VPagePadding(
          applyBottomSafeArea: true,
          vertical: VSpacing.space2,
          child: VButton(
            label: 'Hoàn tất',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

class _ResultLinkTile extends StatelessWidget {
  const _ResultLinkTile({
    required this.label,
    required this.count,
    this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: VText(
              '$label ($count)',
              variant: VTextVariant.bodyDefault,
            ),
          ),
          VIcon(
            icon: VIcons.chevronRight,
            size: VSpacing.space4 + VSpacing.space1,
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }
}
