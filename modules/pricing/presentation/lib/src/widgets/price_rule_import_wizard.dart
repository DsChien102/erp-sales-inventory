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
    this.onContinue,
    this.onClearFile,
    this.onFinish,
    this.onBackToChooseFile,
    this.isDownloadingTemplate = false,
  });

  final PriceRuleImportCubit cubit;
  final PriceRuleImportState state;
  final VoidCallback? onPickFile;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onContinue;
  final VoidCallback? onClearFile;
  final VoidCallback? onFinish;
  final VoidCallback? onBackToChooseFile;
  final bool isDownloadingTemplate;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PriceRuleImportNoPermission() => const VEmptyState(
        icon: VIcons.ban,
        title: 'Không có quyền import',
        description:
            'Bạn không có quyền nhập giá riêng từ Excel. '
            'Liên hệ quản trị viên nếu cần truy cập.',
      ),
      PriceRuleImportLoading(:final message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSkeleton(width: 48, height: 48),
            if (message != null) ...[
              const VGap.md(),
              VText(
                message,
                variant: VTextVariant.bodySmall,
                color: context.vColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
      PriceRuleImportInitial() ||
      PriceRuleImportFileSelected() => PriceRuleImportChooseFileView(
        onPickFile: onPickFile,
        onDownloadTemplate: onDownloadTemplate,
        onContinue: onContinue,
        onClearFile: onClearFile,
        isDownloadingTemplate: isDownloadingTemplate,
        selectedFileName: state is PriceRuleImportFileSelected
            ? (state as PriceRuleImportFileSelected).fileName
            : null,
        selectedFileSizeBytes: state is PriceRuleImportFileSelected
            ? (state as PriceRuleImportFileSelected).fileSizeBytes
            : null,
      ),
      PriceRuleImportPreview(
        :final importDetail,
        :final rows,
        :final readOnly,
        :final initialTab,
      ) =>
        PriceRuleImportPreviewView(
          cubit: cubit,
          importDetail: importDetail,
          rows: rows,
          readOnly: readOnly,
          initialTab: initialTab,
          onBack: readOnly
              ? cubit.backToResult
              : (onBackToChooseFile ?? cubit.backToChooseFile),
        ),
      PriceRuleImportConfirm(
        :final importDetail,
        :final acknowledgeWarningRows,
        :final isRefreshingMode,
      ) =>
        PriceRuleImportConfirmView(
          cubit: cubit,
          importDetail: importDetail,
          acknowledgeWarningRows: acknowledgeWarningRows,
          isRefreshingMode: isRefreshingMode,
        ),
      PriceRuleImportResult(:final result, :final outcome) =>
        PriceRuleImportResultView(
          result: result,
          outcome: outcome,
          onFinish: onFinish,
          onViewValid: () => cubit.reopenPreviewFromResult(
            tab: PriceRuleImportPreviewTab.valid,
          ),
          onViewWarnings: () => cubit.reopenPreviewFromResult(
            tab: PriceRuleImportPreviewTab.warning,
          ),
          onViewErrors: () => cubit.reopenPreviewFromResult(
            tab: PriceRuleImportPreviewTab.error,
          ),
        ),
      PriceRuleImportError(:final code) => VEmptyState(
        icon: VIcons.error,
        title: 'Đã có lỗi xảy ra',
        description: _errorMessage(code),
        actionLabel: 'Thử lại',
        onActionPressed: onBackToChooseFile ?? cubit.backToChooseFile,
      ),
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
    return VPagePadding(
      vertical: VSpacing.space3,
      child: VSteps(
        currentStep: step.index,
        steps: [
          for (final label in _labels) VStepItem(title: label),
        ],
      ),
    );
  }
}
