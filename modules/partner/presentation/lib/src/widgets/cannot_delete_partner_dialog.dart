import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class CannotDeletePartnerDialog extends StatelessWidget {
  const CannotDeletePartnerDialog({super.key});

  /// Returns `true` if the user chose to deactivate instead.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CannotDeletePartnerDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VRadius.sheet),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Không thể xóa KH & NCC',
                      style: VTypography.headingH3.copyWith(
                        color: dynamicColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Icon(Icons.close, color: dynamicColors.textPrimary, size: 24),
                  ),
                ],
              ),
            ),
            Divider(color: dynamicColors.borderDefault, height: 1),
            Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KH & NCC đã có giao dịch phát sinh. Bạn có thể ngừng hoạt động KH & NCC để không sử dụng cho giao dịch mới.',
                    style: VTypography.bodyDefault.copyWith(
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space6),
                  Row(
                    children: [
                      Expanded(
                        child: VButton(
                          label: 'Đóng',
                          variant: VButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: VSpacing.space3),
                      Expanded(
                        child: VButton(
                          label: 'Ngừng hoạt động',
                          variant: VButtonVariant.warning,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
