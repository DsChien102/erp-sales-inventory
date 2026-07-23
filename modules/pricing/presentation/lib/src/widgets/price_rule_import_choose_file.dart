import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'price_rule_import_shared.dart';

/// SG-04 D-01 — Chọn file Excel import giá riêng.
class PriceRuleImportChooseFileView extends StatelessWidget {
  const PriceRuleImportChooseFileView({
    super.key,
    this.onPickFile,
    this.onDownloadTemplate,
    this.onContinue,
    this.onClearFile,
    this.selectedFileName,
    this.selectedFileSizeBytes,
    this.isDownloadingTemplate = false,
    this.accessDenied = false,
    this.isFileInvalid = false,
    this.isDragOver = false,
  });

  final VoidCallback? onPickFile;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onContinue;
  final VoidCallback? onClearFile;
  final String? selectedFileName;
  final int? selectedFileSizeBytes;
  final bool isDownloadingTemplate;

  /// Chặn quyền — drop zone + actions disabled.
  final bool accessDenied;

  /// File đã chọn/thả nhưng không hợp lệ (định dạng / đọc lỗi).
  final bool isFileInvalid;

  /// Đang kéo file vào vùng thả (highlight visual).
  final bool isDragOver;

  VFileDropZoneState get _dropZoneState {
    if (accessDenied) return VFileDropZoneState.disabled;
    if (isDragOver) return VFileDropZoneState.valid;
    if (isFileInvalid && selectedFileName == null) {
      return VFileDropZoneState.invalid;
    }
    return VFileDropZoneState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedFile = selectedFileName != null;
    final canContinue = !accessDenied && hasSelectedFile && !isFileInvalid;
    final interactive = !accessDenied;
    final dropState = _dropZoneState;
    final colors = context.vColors;

    final dropTitle = switch (dropState) {
      VFileDropZoneState.disabled => 'Không có quyền nhập',
      VFileDropZoneState.invalid => 'File không hợp lệ',
      VFileDropZoneState.valid when isDragOver => 'Thả file để nhập',
      _ => 'Kéo & thả file vào đây',
    };

    final dropSubtitle = switch (dropState) {
      VFileDropZoneState.disabled =>
        'Liên hệ quản trị viên nếu cần truy cập',
      VFileDropZoneState.invalid =>
        'Chỉ nhận file .xlsx đúng mẫu',
      VFileDropZoneState.valid when isDragOver => 'Chỉ nhận file .xlsx',
      _ => 'hoặc',
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
                  const VGap.md(),
                  VFileDropZone(
                    state: dropState,
                    title: dropTitle,
                    subtitle: dropSubtitle,
                    action: dropState == VFileDropZoneState.disabled
                        ? null
                        : VButton(
                            label: 'Chọn file từ thiết bị',
                            variant: VButtonVariant.outline,
                            size: VButtonSize.small,
                            onPressed: interactive ? onPickFile : null,
                          ),
                  ),
                  if (hasSelectedFile) ...[
                    const VGap.md(),
                    _SelectedFileCard(
                      fileName: selectedFileName!,
                      sizeLabel: selectedFileSizeBytes != null
                          ? _formatFileSize(selectedFileSizeBytes!)
                          : null,
                      isInvalid: isFileInvalid,
                      onClear: interactive ? onClearFile : null,
                    ),
                  ],
                  const VGap.md(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _DownloadTemplateLink(
                      onPressed: interactive ? onDownloadTemplate : null,
                      isLoading: isDownloadingTemplate,
                      color: colors.primary,
                    ),
                  ),
                  const VGap.lg(),
                  const VBanner(
                    status: VBannerStatus.success,
                    title: 'Lưu ý trước khi nhập',
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PriceRuleImportBullet(
                          'File phải dùng định dạng mẫu (.xlsx)',
                        ),
                        PriceRuleImportBullet(
                          'Mỗi dòng là 1 rule: Khách hàng x Sản phẩm x Đơn vị',
                        ),
                        PriceRuleImportBullet('Giá nhập phải >= 0'),
                        PriceRuleImportBullet('Hệ thống sẽ bỏ qua dòng lỗi'),
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
            label: 'Tiếp tục',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: canContinue ? onContinue : null,
          ),
        ),
      ],
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.fileName,
    this.sizeLabel,
    this.isInvalid = false,
    this.onClear,
  });

  final String fileName;
  final String? sizeLabel;
  final bool isInvalid;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final meta = [
      if (sizeLabel != null) sizeLabel!,
      if (isInvalid) 'File không hợp lệ',
    ].join(' · ');

    return VCard(
      child: Row(
        children: [
          VIcon(
            icon: VIcons.fileSpreadsheet,
            size: VSpacing.space8,
            color: isInvalid ? colors.danger : colors.success,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  fileName,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  color: isInvalid ? colors.danger : null,
                ),
                if (meta.isNotEmpty) ...[
                  const VGap.xs(),
                  VText(
                    meta,
                    variant: VTextVariant.bodySmall,
                    color: isInvalid ? colors.danger : colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(VRadius.r8),
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space1),
                child: VIcon(
                  icon: VIcons.delete,
                  size: VSpacing.space5,
                  color: colors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadTemplateLink extends StatelessWidget {
  const _DownloadTemplateLink({
    required this.onPressed,
    required this.color,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
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
                  color: color,
                ),
              )
            else
              VIcon(
                icon: VIcons.download,
                size: VSpacing.space4,
                color: onPressed == null
                    ? context.vColors.disabledFg
                    : color,
              ),
            const VGap.horizontalXs(),
            VText(
              'Tải file mẫu nhập giá riêng',
              variant: VTextVariant.bodySmall,
              color: onPressed == null
                  ? context.vColors.disabledFg
                  : color,
            ),
          ],
        ),
      ),
    );
  }
}
