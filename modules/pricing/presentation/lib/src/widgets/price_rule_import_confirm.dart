import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_cubit.dart';
import 'price_rule_import_shared.dart';

/// SG-04 — Xác nhận import (không có "Hiệu lực mặc định").
class PriceRuleImportConfirmView extends StatelessWidget {
  const PriceRuleImportConfirmView({
    super.key,
    required this.cubit,
    required this.importDetail,
    required this.acknowledgeWarningRows,
  });

  final PriceRuleImportCubit cubit;
  final CustomerPriceRuleImportDetailDto importDetail;
  final bool acknowledgeWarningRows;

  @override
  Widget build(BuildContext context) {
    final batch = importDetail.batch;
    final importableRows = batch.validRows + batch.warningRows;
    final warningAcknowledged =
        batch.warningRows == 0 || acknowledgeWarningRows;
    final colors = context.vColors;
    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VGap.md(),
          VSection(
            title: 'Tóm tắt import',
            child: VCard(
              padding: const EdgeInsets.all(VSpacing.space3),
              child: Column(
                children: [
                  PriceRuleImportConfirmRow(
                    label: 'Tổng dòng trong file',
                    value: '${batch.totalRows}',
                  ),
                  PriceRuleImportConfirmRow(
                    label: 'Hợp lệ',
                    value: '${batch.validRows}',
                    color: colors.success,
                  ),
                  PriceRuleImportConfirmRow(
                    label: 'Cảnh báo',
                    value: '${batch.warningRows}',
                    color: colors.warning,
                  ),
                  PriceRuleImportConfirmRow(
                    label: 'Lỗi (bỏ qua)',
                    value: '${batch.errorRows}',
                    color: colors.danger,
                  ),
                ],
              ),
            ),
          ),
          const VGap.md(),
          VSection(
            title: 'Xử lý khi trùng rule',
            child: VCard(
              padding: const EdgeInsets.all(VSpacing.space3),
              child: VText(
                'Cập nhật giá hiện tại (ghi đè) khi trùng khách hàng / sản phẩm / đơn vị.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),
          ),
          if (batch.warningRows > 0) ...[
            const VGap.md(),
            VCheckbox(
              value: acknowledgeWarningRows,
              onChanged: (v) => cubit.acknowledgeWarnings(v ?? false),
              label: 'Tôi đã xem xét và muốn giữ các dòng cảnh báo',
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Quay lại',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: cubit.backToPreview,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VButton(
                  label: 'Import ($importableRows dòng)',
                  variant: VButtonVariant.primary,
                  fullWidth: true,
                  onPressed: importableRows > 0 && warningAcknowledged
                      ? () => cubit.confirmImport(
                          acknowledgeWarningRows: acknowledgeWarningRows,
                        )
                      : null,
                ),
              ),
            ],
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}
