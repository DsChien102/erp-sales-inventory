import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_import_cubit.dart';
import 'price_rule_import_shared.dart';

/// SG-04 — Xác nhận import (không có "Hiệu lực mặc định").
///
/// Radio map `CustomerPriceRuleImportMode` (phương án B).
class PriceRuleImportConfirmView extends StatelessWidget {
  const PriceRuleImportConfirmView({
    super.key,
    required this.cubit,
    required this.importDetail,
    required this.acknowledgeWarningRows,
    this.isRefreshingMode = false,
  });

  final PriceRuleImportCubit cubit;
  final CustomerPriceRuleImportDetailDto importDetail;
  final bool acknowledgeWarningRows;
  final bool isRefreshingMode;

  @override
  Widget build(BuildContext context) {
    final batch = importDetail.batch;
    final importableRows = batch.validRows + batch.warningRows;
    final warningAcknowledged =
        batch.warningRows == 0 || acknowledgeWarningRows;
    final colors = context.vColors;
    final canInteract = !isRefreshingMode;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isRefreshingMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: VPagePadding(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const VGap.md(),
                        VText(
                          'Chỉ nhập các dữ liệu hợp lệ',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.md(),
                        VSection(
                          title: 'Tóm tắt lần nhập',
                          child: VCard(
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
                          title:
                              'Xử lý khi trùng rule (khách hàng + sản phẩm + đơn vị)',
                          child: VCard(
                            child: VChoiceList<CustomerPriceRuleImportMode>(
                              titleHidden: true,
                              enabled: canInteract,
                              selected: [cubit.importMode],
                              choices: const [
                                VChoiceOption(
                                  value: CustomerPriceRuleImportMode.upsert,
                                  label: 'Cập nhật giá nhớ hiện tại',
                                  helpText:
                                      'Cập nhật rule đã khớp; tạo mới nếu chưa có.',
                                ),
                                VChoiceOption(
                                  value: CustomerPriceRuleImportMode.createOnly,
                                  label: 'Bỏ qua, giữ nguyên giá hiện tại',
                                  helpText:
                                      'Không cập nhật rule đang có; chỉ tạo dòng mới.',
                                ),
                                VChoiceOption(
                                  value: CustomerPriceRuleImportMode.updateOnly,
                                  label: 'Chỉ cập nhật rule đã có',
                                  helpText:
                                      'Bỏ qua dòng tạo mới; chỉ xử lý dòng khớp rule.',
                                ),
                              ],
                              onChanged: (selected) {
                                if (!canInteract || selected.isEmpty) return;
                                cubit.setImportMode(selected.first);
                              },
                            ),
                          ),
                        ),
                        if (batch.warningRows > 0) ...[
                          const VGap.md(),
                          VCheckbox(
                            value: acknowledgeWarningRows,
                            enabled: canInteract,
                            onChanged: (v) =>
                                cubit.acknowledgeWarnings(v ?? false),
                            label:
                                'Tôi đã xem xét và muốn giữ các dòng cảnh báo',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              VPagePadding(
                applyBottomSafeArea: true,
                vertical: VSpacing.space2,
                child: Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Quay lại',
                        variant: VButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: canInteract ? cubit.backToPreview : null,
                      ),
                    ),
                    const VGap.horizontalMd(),
                    Expanded(
                      child: VButton(
                        label: 'Nhập ($importableRows dòng)',
                        variant: VButtonVariant.primary,
                        fullWidth: true,
                        onPressed:
                            canInteract &&
                                importableRows > 0 &&
                                warningAcknowledged
                            ? () => cubit.confirmImport(
                                acknowledgeWarningRows: acknowledgeWarningRows,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isRefreshingMode)
          Positioned.fill(
            child: Center(
              child: Material(
                color: colors.surface,
                elevation: 2,
                borderRadius: BorderRadius.circular(VRadius.r16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: VSpacing.space6,
                    vertical: VSpacing.space8,
                  ),
                  child: VLoading(
                    title: 'Đang kiểm tra lại...',
                    description: 'Áp dụng cách xử lý trùng rule mới',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
