import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../cubit/price_rule_import_cubit.dart';
import '../cubit/price_rule_import_state.dart';
import 'price_rule_import_choose_file.dart';
import 'price_rule_import_confirm.dart';
import 'price_rule_import_preview.dart';
import 'price_rule_import_result.dart';

/// Wizard import Excel 4 bước (SG-04) — composition root.
class PriceRuleImportWizard extends StatelessWidget {
  const PriceRuleImportWizard({
    super.key,
    required this.cubit,
    required this.state,
    this.onPickFile,
    this.onDownloadTemplate,
    this.onFinish,
    this.onBackToChooseFile,
    this.isDownloadingTemplate = false,
  });

  final PriceRuleImportCubit cubit;
  final PriceRuleImportState state;
  final VoidCallback? onPickFile;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onFinish;
  final VoidCallback? onBackToChooseFile;
  final bool isDownloadingTemplate;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PriceRuleImportInitial() ||
      PriceRuleImportFileSelected() => PriceRuleImportChooseFileView(
        onPickFile: onPickFile,
        onDownloadTemplate: onDownloadTemplate,
        isDownloadingTemplate: isDownloadingTemplate,
        selectedFileName: state is PriceRuleImportFileSelected
            ? (state as PriceRuleImportFileSelected).fileName
            : null,
      ),
      PriceRuleImportLoading(:final step)
          when step == PriceRuleImportStep.preview ||
              step == PriceRuleImportStep.confirm ||
              step == PriceRuleImportStep.result =>
        const Center(child: VSkeleton(width: 48, height: 48)),
      PriceRuleImportPreview(:final importDetail, :final rows) =>
        PriceRuleImportPreviewView(
          cubit: cubit,
          importDetail: importDetail,
          rows: rows,
          onBack: onBackToChooseFile,
        ),
      PriceRuleImportConfirm(
        :final importDetail,
        :final acknowledgeWarningRows,
      ) =>
        PriceRuleImportConfirmView(
          cubit: cubit,
          importDetail: importDetail,
          acknowledgeWarningRows: acknowledgeWarningRows,
        ),
      PriceRuleImportResult(:final result) => PriceRuleImportResultView(
        result: result,
        onFinish: onFinish,
      ),
      PriceRuleImportError(:final code) => VEmptyState(
        icon: VIcons.error,
        title: 'Đã có lỗi xảy ra',
        description: _errorMessage(code),
        actionLabel: 'Thử lại',
        onActionPressed: onBackToChooseFile ?? cubit.backToChooseFile,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  String _errorMessage(String code) => switch (code) {
    'NO_PERMISSION' => 'Bạn không có quyền import giá riêng.',
    'SYSTEM_ERROR' => 'Lỗi hệ thống. Vui lòng thử lại.',
    'TEMPLATE_VERSION_UNSUPPORTED' =>
      'Phiên bản file mẫu không được hỗ trợ. Vui lòng tải lại file mẫu mới nhất.',
    'TEMPLATE_HEADER_INVALID' =>
      'Các cột tiêu đề không đúng file mẫu. Vui lòng dùng file mẫu mới nhất.',
    'TEMPLATE_SHEET_INVALID' =>
      'Không tìm thấy sheet dữ liệu đúng định dạng trong file.',
    'EMPTY_FILE' => 'File không có dòng dữ liệu để import.',
    'FORMULA_NOT_SUPPORTED' =>
      'File có ô công thức. Vui lòng chuyển công thức thành giá trị trước khi import.',
    'UNSUPPORTED_FILE_TYPE' => 'File không đúng định dạng .xlsx.',
    'ROW_LIMIT_EXCEEDED' => 'File vượt quá số dòng cho phép.',
    'ARCHIVE_LIMIT_EXCEEDED' =>
      'File Excel quá lớn hoặc có cấu trúc archive không hợp lệ.',
    'IMPORT_FILE_INVALID' => 'File import không hợp lệ.',
    _ => 'Đã có lỗi: $code',
  };
}

/// Indicator tiến trình import (chọn file → kiểm tra → xác nhận → kết quả).
class PriceRuleImportStepIndicator extends StatelessWidget {
  const PriceRuleImportStepIndicator({super.key, required this.step});

  final PriceRuleImportStep step;

  static const _labels = ['Chọn file', 'Kiểm tra', 'Xác nhận', 'Kết quả'];

  @override
  Widget build(BuildContext context) {
    final current = step.index;
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final isActive = i == current;
          final isDone = i < current;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? colors.success
                            : isActive
                            ? colors.primary
                            : colors.surfaceAlt,
                      ),
                      child: Center(
                        child: isDone
                            ? VIcon(
                                icon: VIcons.check,
                                size: 14,
                                color: colors.surface,
                              )
                            : VText(
                                '${i + 1}',
                                variant: VTextVariant.monoNumeric,
                                color: isActive
                                    ? colors.surface
                                    : colors.textMuted,
                                style: const TextStyle(fontSize: 12),
                              ),
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      _labels[i],
                      variant: VTextVariant.caption,
                      color: isDone || isActive
                          ? colors.textPrimary
                          : colors.textMuted,
                    ),
                  ],
                ),
                if (i < _labels.length - 1)
                  Expanded(
                    child: Divider(
                      color: isDone ? colors.success : colors.borderDefault,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
