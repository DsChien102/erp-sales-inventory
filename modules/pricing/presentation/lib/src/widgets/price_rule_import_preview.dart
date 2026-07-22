import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_cubit.dart';
import 'price_rule_import_shared.dart';

/// SG-04 — Preview dòng import trước khi xác nhận.
class PriceRuleImportPreviewView extends StatelessWidget {
  const PriceRuleImportPreviewView({
    super.key,
    required this.cubit,
    required this.importDetail,
    required this.rows,
    this.onBack,
  });

  final PriceRuleImportCubit cubit;
  final CustomerPriceRuleImportDetailDto importDetail;
  final List<CustomerPriceRuleImportRowPreviewDto> rows;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final batch = importDetail.batch;
    final colors = context.vColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Row(
            children: [
              PriceRuleImportStatChip(
                label: 'Tổng',
                value: batch.totalRows,
                color: colors.textPrimary,
              ),
              const VGap.horizontalSm(),
              PriceRuleImportStatChip(
                label: 'Hợp lệ',
                value: batch.validRows,
                color: colors.success,
              ),
              const VGap.horizontalSm(),
              PriceRuleImportStatChip(
                label: 'Cảnh báo',
                value: batch.warningRows,
                color: colors.warning,
              ),
              const VGap.horizontalSm(),
              PriceRuleImportStatChip(
                label: 'Lỗi',
                value: batch.errorRows,
                color: colors.danger,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const VGap.xs(),
            itemBuilder: (ctx, i) => PriceRuleImportRowTile(row: rows[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onBack ?? cubit.backToChooseFile,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  label: 'Tiếp tục',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: batch.validRows + batch.warningRows > 0
                      ? cubit.proceedToConfirm
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
