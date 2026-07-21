import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'price_rule_import_shared.dart';

/// SG-04 — Chọn file Excel import giá riêng.
class PriceRuleImportChooseFileView extends StatelessWidget {
  const PriceRuleImportChooseFileView({
    super.key,
    this.onPickFile,
    this.onDownloadTemplate,
    this.selectedFileName,
  });

  final VoidCallback? onPickFile;
  final VoidCallback? onDownloadTemplate;
  final String? selectedFileName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VGap.lg(),
          GestureDetector(
            onTap: onPickFile,
            child: VCard(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VIcon(
                      icon: VIcons.cloud,
                      size: 40,
                      color: colors.textMuted,
                    ),
                    const VGap.sm(),
                    VText(
                      'Kéo & thả file vào đây',
                      variant: VTextVariant.bodyDefault,
                    ),
                    const VGap.xs(),
                    VText(
                      'Định dạng .xlsx',
                      variant: VTextVariant.bodySmall,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedFileName != null) ...[
            const VGap.md(),
            VCard(
              padding: const EdgeInsets.all(VSpacing.space3),
              child: Row(
                children: [
                  VIcon(icon: VIcons.receipt, color: colors.primary),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VText(
                      selectedFileName!,
                      variant: VTextVariant.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const VGap.md(),
          VButton(
            label: 'Chọn file từ thiết bị',
            variant: VButtonVariant.primary,
            fullWidth: true,
            onPressed: onPickFile,
          ),
          const VGap.sm(),
          VButton(
            label: 'Tải file mẫu import giá riêng',
            variant: VButtonVariant.ghost,
            fullWidth: true,
            onPressed: onDownloadTemplate,
          ),
          const VGap.lg(),
          const VSection(
            title: 'Lưu ý trước khi import',
            child: VCard(
              padding: EdgeInsets.all(VSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceRuleImportBullet('File định dạng .xlsx, một rule mỗi dòng'),
                  PriceRuleImportBullet('Giá phải ≥ 0'),
                  PriceRuleImportBullet('Hệ thống bỏ qua các dòng lỗi'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
