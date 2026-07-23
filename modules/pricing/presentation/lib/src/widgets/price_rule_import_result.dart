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
    this.onDownloadLog,
    this.isDownloadingLog = false,
  });

  final CustomerPriceRuleImportResultDto result;
  final PriceRuleImportOutcome outcome;
  final VoidCallback? onFinish;
  final VoidCallback? onViewValid;
  final VoidCallback? onViewWarnings;
  final VoidCallback? onViewErrors;
  final VoidCallback? onDownloadLog;
  final bool isDownloadingLog;

  @override
  Widget build(BuildContext context) {
    final batch = result.batch;
    final colors = context.vColors;
    final (icon, tone, title, subtitle) = switch (outcome) {
      PriceRuleImportOutcome.success => (
        VIcons.check,
        VComponentTone.success,
        'Nhập thành công!',
        'Đã nhập ${batch.importedRows} dòng giá nhớ.',
      ),
      PriceRuleImportOutcome.partial => (
        VIcons.warning,
        VComponentTone.warning,
        'Nhập một phần',
        'Đã nhập ${batch.importedRows} dòng. '
            'Một số dòng bị bỏ qua hoặc lỗi.',
      ),
      PriceRuleImportOutcome.failed => (
        VIcons.error,
        VComponentTone.danger,
        'Nhập thất bại',
        'Không có dòng nào được nhập. Vui lòng kiểm tra lại file.',
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
                          label: 'Tổng dòng trong file',
                          value: '${batch.totalRows}',
                        ),
                        PriceRuleImportConfirmRow(
                          label: 'Đã nhập thành công',
                          value: '${batch.importedRows}',
                          color: colors.success,
                        ),
                        PriceRuleImportConfirmRow(
                          label: 'Cảnh báo (đã bỏ qua)',
                          value: '${batch.warningRows > 0 ? batch.warningRows : batch.skippedRows}',
                          color: colors.warning,
                        ),
                        PriceRuleImportConfirmRow(
                          label: 'Lỗi (đã bỏ qua)',
                          value: '${batch.errorRows > 0 ? batch.errorRows : batch.failedRows}',
                          color: colors.danger,
                        ),
                      ],
                    ),
                  ),
                  const VGap.md(),
                  VSection(
                    title: 'Chi tiết kết quả',
                    trailing: onDownloadLog == null
                        ? null
                        : _DownloadLogButton(
                            onPressed: isDownloadingLog ? null : onDownloadLog,
                            isLoading: isDownloadingLog,
                          ),
                    child: Column(
                      children: [
                        _ResultLinkTile(
                          label: 'Dữ liệu hợp lệ',
                          count: batch.importedRows > 0
                              ? batch.importedRows
                              : batch.validRows,
                          subtitle: 'Đã nhập thành công',
                          subtitleColor: colors.success,
                          onTap: onViewValid,
                        ),
                        const VGap.xs(),
                        _ResultLinkTile(
                          label: 'Cảnh báo',
                          count: batch.warningRows,
                          subtitle: 'Xem chi tiết',
                          onTap: onViewWarnings,
                        ),
                        const VGap.xs(),
                        _ResultLinkTile(
                          label: 'Lỗi',
                          count: batch.errorRows > 0
                              ? batch.errorRows
                              : batch.failedRows,
                          subtitle: 'Xem chi tiết',
                          subtitleColor: colors.danger,
                          labelColor: colors.danger,
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

class _DownloadLogButton extends StatelessWidget {
  const _DownloadLogButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(VRadius.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space1,
          vertical: VSpacing.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: VSpacing.space4,
                height: VSpacing.space4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            else
              VIcon(
                icon: VIcons.download,
                size: VSpacing.space4,
                color: colors.primary,
              ),
            const VGap.horizontalXs(),
            VText(
              'Tải nhật ký nhập (.xlsx)',
              variant: VTextVariant.bodySmall,
              color: colors.primary,
            ),
            VIcon(
              icon: VIcons.chevronRight,
              size: VSpacing.space4,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultLinkTile extends StatelessWidget {
  const _ResultLinkTile({
    required this.label,
    required this.count,
    this.subtitle,
    this.labelColor,
    this.subtitleColor,
    this.onTap,
  });

  final String label;
  final int count;
  final String? subtitle;
  final Color? labelColor;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  '$label ($count)',
                  variant: VTextVariant.bodyDefault,
                  color: labelColor,
                ),
                if (subtitle != null) ...[
                  const VGap.xs(),
                  VText(
                    subtitle!,
                    variant: VTextVariant.bodySmall,
                    color: subtitleColor ?? colors.textSecondary,
                  ),
                ],
              ],
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
