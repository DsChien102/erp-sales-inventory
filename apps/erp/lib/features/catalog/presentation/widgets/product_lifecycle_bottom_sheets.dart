import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_application/application.dart';

class _VLifecycleBottomSheetContent extends StatelessWidget {
  final String message;
  final String cancelLabel;
  final String actionLabel;
  final bool isDestructive;
  final VoidCallback onAction;
  final List<ProductBusinessStatusWarningDto>? warnings;

  const _VLifecycleBottomSheetContent({
    required this.message,
    required this.cancelLabel,
    required this.actionLabel,
    this.isDestructive = false,
    required this.onAction,
    this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            if (warnings != null && warnings!.isNotEmpty) ...[
              const SizedBox(height: VSpacing.space4),
              Container(
                padding: const EdgeInsets.all(VSpacing.space3),
                decoration: BoxDecoration(
                  color: dynamicColors.warningBg,
                  border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(VRadius.r8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VIcon(icon: VIcons.warning, color: dynamicColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Cần xác nhận',
                          style: VTypography.bodySmall.copyWith(
                            color: dynamicColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings!.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: dynamicColors.warning)),
                            Expanded(
                              child: Text(
                                w.message,
                                style: VTypography.bodySmall.copyWith(
                                  color: dynamicColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: cancelLabel,
                    variant: VButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VButton(
                    label: actionLabel,
                    variant: isDestructive ? VButtonVariant.danger : VButtonVariant.primary,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAction();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showProductDeactivateBottomSheet({
  required BuildContext context,
  required VoidCallback onConfirm,
  List<ProductBusinessStatusWarningDto>? warnings,
}) {
  return showVBottomSheet(
    context: context,
    title: 'Ngừng kinh doanh sản phẩm này?',
    child: _VLifecycleBottomSheetContent(
      message:
          'Sản phẩm sẽ không xuất hiện khi tạo đơn mới. Dữ liệu đơn cũ vẫn giữ nguyên. Bạn có thể mở lại bất cứ lúc nào.',
      cancelLabel: 'Huỷ',
      actionLabel: 'Ngừng kinh doanh',
      isDestructive: true,
      onAction: onConfirm,
      warnings: warnings,
    ),
  );
}

Future<void> showProductReactivateBottomSheet({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  return showVBottomSheet(
    context: context,
    title: 'Kinh doanh lại sản phẩm này?',
    child: _VLifecycleBottomSheetContent(
      message: 'Sản phẩm sẽ xuất hiện lại khi tạo đơn và nhập hàng.',
      cancelLabel: 'Huỷ',
      actionLabel: 'Kinh doanh lại',
      isDestructive: true,
      onAction: onConfirm,
    ),
  );
}
