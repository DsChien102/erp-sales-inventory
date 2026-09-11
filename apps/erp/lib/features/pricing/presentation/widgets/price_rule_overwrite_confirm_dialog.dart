import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// SG-03 — VBottomSheet xác nhận tự động ghi đè khi tạo mới giá riêng bị trùng khoảng hiệu lực.
Future<bool> showPriceRuleOverwriteConfirmDialog(BuildContext context) async {
  final result = await showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Xác nhận tự động ghi đè giá riêng',
    child: const _PriceRuleOverwriteConfirmSheet(),
  );
  return result ?? false;
}

class _PriceRuleOverwriteConfirmSheet extends StatelessWidget {
  const _PriceRuleOverwriteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: VText(
                      'Tự động ghi đè giá trùng?',
                      variant: VTextVariant.headingH3,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      color: colors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space1),
                      child: VIcon(
                        icon: VIcons.close,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.xs(),
              VText(
                'Bạn có chắc muốn tự động ghi đè giá riêng này?',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.md(),
              const VBanner(
                tone: VComponentTone.info,
                icon: VIcons.info,
                title: 'Lưu ý tự động ghi đè',
                message:
                    'Tạo giá riêng này sẽ tự động ghi đè giá riêng đang áp dụng trùng khoảng thời gian (nếu có).',
              ),
              const VGap.lg(),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: VButton(
                      label: 'Ghi đè & Lưu',
                      variant: VButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
