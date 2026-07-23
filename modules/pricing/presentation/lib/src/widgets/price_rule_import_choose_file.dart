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
  });

  final VoidCallback? onPickFile;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onContinue;
  final VoidCallback? onClearFile;
  final String? selectedFileName;
  final int? selectedFileSizeBytes;
  final bool isDownloadingTemplate;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasFile = selectedFileName != null;

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
                  VCard(
                    onTap: onPickFile,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const VGap.lg(),
                        VIcon(
                          icon: VIcons.cloud,
                          size: VSpacing.space10,
                          color: colors.primary,
                        ),
                        const VGap.sm(),
                        const VText(
                          'Kéo & thả file vào đây',
                          variant: VTextVariant.bodyDefault,
                        ),
                        const VGap.xs(),
                        VText(
                          'hoặc chọn file .xlsx từ thiết bị',
                          variant: VTextVariant.bodySmall,
                          color: colors.textMuted,
                        ),
                        const VGap.lg(),
                      ],
                    ),
                  ),
                  if (hasFile) ...[
                    const VGap.md(),
                    VCard(
                      child: Row(
                        children: [
                          VIcon(icon: VIcons.receipt, color: colors.primary),
                          const VGap.horizontalSm(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VText(
                                  selectedFileName!,
                                  variant: VTextVariant.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (selectedFileSizeBytes != null)
                                  VText(
                                    _formatFileSize(selectedFileSizeBytes!),
                                    variant: VTextVariant.caption,
                                    color: colors.textMuted,
                                  ),
                              ],
                            ),
                          ),
                          if (onClearFile != null)
                            VIconBox(
                              icon: VIcons.close,
                              size: VSpacing.space8,
                              iconSize: VSpacing.space4,
                              isCircular: true,
                              tone: VComponentTone.neutral,
                              onTap: onClearFile,
                            ),
                        ],
                      ),
                    ),
                  ],
                  const VGap.md(),
                  VButton(
                    label: hasFile ? 'Chọn file khác' : 'Chọn file từ thiết bị',
                    variant: hasFile
                        ? VButtonVariant.secondary
                        : VButtonVariant.primary,
                    fullWidth: true,
                    onPressed: onPickFile,
                  ),
                  const VGap.sm(),
                  VButton(
                    label: 'Tải file mẫu import giá riêng',
                    variant: VButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: onDownloadTemplate,
                    isLoading: isDownloadingTemplate,
                  ),
                  const VGap.lg(),
                  const VSection(
                    title: 'Lưu ý trước khi import',
                    child: VCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PriceRuleImportBullet(
                            'File định dạng .xlsx, một rule mỗi dòng',
                          ),
                          PriceRuleImportBullet('Giá phải lớn hơn 0'),
                          PriceRuleImportBullet(
                            'Dòng lỗi sẽ bị bỏ qua; rule active trùng không bị ghi đè',
                          ),
                        ],
                      ),
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
            onPressed: hasFile ? onContinue : null,
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
